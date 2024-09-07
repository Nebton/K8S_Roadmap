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

                    def branchName = env.BRANCH_NAME ?: env.GIT_BRANCH ?: sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()

                    if (branchName == 'master') {
                        env.DEPLOY_ENV = 'prod'
                    } else if (branchName == 'staging') {
                        env.DEPLOY_ENV = 'staging'
                    } else if (branchName == 'dev'){
                        env.DEPLOY_ENV = 'dev'
                    }
                }
            }
        }


        stage('Debug') {
            steps {
                script {
                    echo "Branch Name: ${branchName}"
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
        
        stage('Deploy') {
            steps {
                    sh "helm upgrade --install k8s-roadmap ./helm/k8s-roadmap/ --namespace ${env.DEPLOY_ENV} --set global.environment=${env.DEPLOY_ENV} --set backend.image.tag=backend-$GIT_COMMIT --set frontend.image.tag=frontend-$GIT_COMMIT"
                } 
            }
        }
    }
