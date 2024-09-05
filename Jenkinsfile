pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE_BACKEND = "nebton544/k8s_roadmap"
        DOCKER_IMAGE_FRONTEND = "nebton544/k8s_roadmap"
        KUBECONFIG = '~/.kube/config'
    }
    
    stages {
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
                sh "helm upgrade --install k8s-roadmap ./charts/k8s-roadmap --set backend.image.tag=backend-$GIT_COMMIT --set frontend.image.tag=frontend-$GIT_COMMIT"
            }
        }
    }
}
