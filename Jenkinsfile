pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE_BACKEND = "nebton544/k8s_roadmap"
        DOCKER_IMAGE_FRONTEND = "nebton544/k8s_roadmap"
        KUBECONFIG = "/var/jenkins_home/config"
    }
    
    stages {

        stage('Determine Environment') {
            steps {
                script {

                    if (env.GIT_BRANCH == 'origin/master') {
                        env.DEPLOY_ENV = 'prod'
                    } else if (env.GIT_BRANCH == 'origin/staging') {
                        env.DEPLOY_ENV = 'staging'
                    } else if (env.GIT_BRANCH == 'origin/dev'){
                        env.DEPLOY_ENV = 'dev'
                    }
                }
            }
        }


        stage('Debug') {
            steps {
                script {
                    echo "Branch Name: ${env.GIT_BRANCH}"
                    echo "Deploy Environment: ${env.DEPLOY_ENV}"
                }
            }
        }


        stage('Build') {
            steps {
                sh 'docker build -t $DOCKER_IMAGE_BACKEND:backend-$GIT_COMMIT ./backend'
                sh 'docker build -t $DOCKER_IMAGE_FRONTEND:frontend-$GIT_COMMIT ./frontend'
            }
        }
        
        stage('Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                    sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
                    sh 'docker push $DOCKER_IMAGE_BACKEND:backend-$GIT_COMMIT'
                    sh 'docker push $DOCKER_IMAGE_FRONTEND:frontend-$GIT_COMMIT'
                }
            }
        }
        
        stage('Deploy ConfigMap') {
            steps {
                script {
                    sh "kubectl apply -f kubernetes/${env.DEPLOY_ENV}-config.yaml"
                }
            }
        }

        stage('Deploy') {
            steps {
                    sh "helm upgrade --install k8s-roadmap ./helm/k8s-roadmap/ --namespace ${env.DEPLOY_ENV} --set global.environment=${env.DEPLOY_ENV} --set backend.image.tag=backend-$GIT_COMMIT --set frontend.image.tag=frontend-$GIT_COMMIT"
                    sh "kubectl apply -f kubernetes/node-exporter-deployment.yaml"
            }
        stage('Monitor') {
            steps {
                sh "helm repo add prometheus-community https://prometheus-community.github.io/helm-charts"
                sh "helm repo update"
                sh "helm upgrade --install prometheus prometheus-community/kube-prometheus-stack -f kubernetes/prometheus-values.yaml -n prod"
                }
            }
        }
    }
