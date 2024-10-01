pipeline {
    agent any

    parameters {
        string(name: 'BACKEND_VERSIONS', defaultValue: 'v1,v2', description: 'Comma-separated list of backend versions to deploy')
    }

    environment {
        DOCKER_IMAGE_BACKEND = "nebton544/k8s_roadmap"
        DOCKER_IMAGE_FRONTEND = "nebton544/k8s_roadmap"
        KUBECONFIG = "/var/jenkins_home/config"
        TF_HOME = tool name: 'Terraform'
        BACKEND_VERSIONS = "${params.BACKEND_VERSIONS}"
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
                sh 'docker build -t $DOCKER_IMAGE_BACKEND:backend-$GIT_COMMIT-v1 ./backend/v1'
                sh 'docker build -t $DOCKER_IMAGE_BACKEND:backend-$GIT_COMMIT-v2 ./backend/v2'
                sh 'docker build -t $DOCKER_IMAGE_FRONTEND:frontend-$GIT_COMMIT ./frontend'
            }
        }
        
        stage('Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                    sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
                    sh 'docker push $DOCKER_IMAGE_BACKEND:backend-$GIT_COMMIT-v1'
                    sh 'docker push $DOCKER_IMAGE_BACKEND:backend-$GIT_COMMIT-v2'
                    sh 'docker push $DOCKER_IMAGE_FRONTEND:frontend-$GIT_COMMIT'
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    script {
                        env.PATH = "${TF_HOME}:${env.PATH}"
                        sh "terraform init"
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    script {
                        sh """
                        def backendVersionsList = BACKEND_VERSIONS.split(',').collect { "\"${it.trim()}\"" }.join(',')
                        terraform plan \
                        -var 'environment=${env.DEPLOY_ENV}' \
                        -var 'backend_image=${DOCKER_IMAGE_BACKEND}:backend-${GIT_COMMIT}' \
                        -var 'frontend_image=${DOCKER_IMAGE_FRONTEND}:frontend-${GIT_COMMIT}' \
                        -var 'backend_versions=[${backendVersionsList}]' \
                        -out tfplan
                        """
                    }
                }
            }
        }
        
        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    script {
                        sh "terraform apply -auto-approve tfplan"
                    }
                }
            }
        }
        //stage('Deploy ConfigMap') {
        //    steps {
        //        script {
        //            sh "kubectl apply -f kubernetes/${env.DEPLOY_ENV}-config.yaml --request-timeout=60s"
        //        }
        //    }
        //}

        //stage('Deploy') {
        //    steps {
        //            sh "helm upgrade --install k8s-roadmap ./helm/k8s-roadmap/ --namespace ${env.DEPLOY_ENV} --set global.environment=${env.DEPLOY_ENV} --set backend.image.tag=backend-$GIT_COMMIT --set frontend.image.tag=frontend-$GIT_COMMIT"
        //
        //    }
        //}


        //stage('Monitor') {
        //    //Prometheus/Grafana stack
        //    steps {
        //        sh "helm repo add prometheus-community https://prometheus-community.github.io/helm-charts"
        //        sh "helm repo update"
        //        sh "helm upgrade --install prometheus prometheus-community/kube-prometheus-stack -f kubernetes/prometheus-values.yaml -n prod"
        //    sh "kubectl apply -f kubernetes/node-exporter-deployment.yaml"
        //        }
        //
        //    //ELLK stack 
        //    steps {
        //        //sh "kubectl create configmap filebeat-configmap --from-file=kubernetes/filebeat-configmap.yaml"
        //        //sh "kubectl create configmap logstash-configmap --from-file=kubernetes/logstash.conf"
        //        //sh "kubectl apply -f kubernetes/elk-stack.yaml -n prod"
        //    }
        //
        //    }
        }
}
