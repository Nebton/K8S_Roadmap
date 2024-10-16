pipeline {
    agent any

    parameters {
        string(name: 'BACKEND_VERSIONS', defaultValue: '["v1","v2"]', description: 'Comma-separated list of backend versions to deploy')
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

        stage('Security Scan and SBOM Generation') {
            steps {
                script {
                    def scanAndGenerateSBOM = { imageName ->
                        def safeImageName = imageName.replaceAll('/', '_').replaceAll(':', '_')
                        
                        // Vulnerability Scan (normal output to console)
                        sh "trivy image --exit-code 0 --severity HIGH,CRITICAL ${imageName}"
                        
                        // Vulnerability Scan (JSON for archiving, suppress stdout)
                        sh "trivy image --exit-code 0 --severity HIGH,CRITICAL ${imageName} -f json > trivy_${safeImageName}.json"
                        
                        // Generate SBOM (suppress stdout)
                        sh "trivy image  ${imageName} --format cyclonedx > sbom_${safeImageName}.json"
                    }
                    
                    // Scan images
                    scanAndGenerateSBOM("$DOCKER_IMAGE_BACKEND:backend-$GIT_COMMIT-v1")
                    scanAndGenerateSBOM("$DOCKER_IMAGE_BACKEND:backend-$GIT_COMMIT-v2")
                    scanAndGenerateSBOM("$DOCKER_IMAGE_FRONTEND:frontend-$GIT_COMMIT")

                    // Archive Trivy results immediately
                    archiveArtifacts artifacts: 'trivy_*.json, sbom_*.json', allowEmptyArchive: true
                }
            }
        }

        stage('Checkov Scans') {
            steps {
                script {
                    // Determine environment
                    def environment = env.DEPLOY_ENV ?: 'default'

                    // Scan Helm charts (suppress stdout for file creation)
                    sh "checkov -d helm/k8s_roadmap --framework kubernetes --output-file-path checkov_${environment}/helm 1>/dev/null || true"

                    // Scan Kubernetes manifests (suppress stdout for file creation)
                    sh "checkov -d kubernetes/ --framework kubernetes --output-file-path checkov_${environment}/kubernetes 1>/dev/null || true"

                    // Scan Terraform code (suppress stdout for file creation)
                    sh "checkov -d terraform/ --framework terraform --output-file-path checkov_${environment}/terraform 1>/dev/null || true"

                    // Archive Checkov results immediately
                    archiveArtifacts artifacts: "checkov_${environment}/*/results_cli.txt", allowEmptyArchive: true
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
                         terraform plan \
                        -var 'environment=${env.DEPLOY_ENV}' \
                        -var 'backend_image=${DOCKER_IMAGE_BACKEND}:backend-${GIT_COMMIT}' \
                        -var 'frontend_image=${DOCKER_IMAGE_FRONTEND}:frontend-${GIT_COMMIT}' \
                        -var 'backend_versions=${BACKEND_VERSIONS}' \
                        -out tfplan
                        """
                    }
                }
            }
        }
        
        stage('Terraform Apply') {
            steps {
                script {
                    dir('terraform') {
                        script {
                            sh "terraform apply -auto-approve tfplan"
                            env.VAULT_NAMESPACE = sh(script: 'terraform output -raw vault_namespace', returnStdout: true).trim()
                            env.POSTGRES_PASSWORD = sh(script: 'terraform output -raw postgres_password', returnStdout: true).trim()
                            env.POSTGRES_NAMESPACE = sh(script: 'terraform output -raw postgres_namespace', returnStdout: true).trim()
                        }
                    }
                    dir('ansible') {
                        withEnv(["VAULT_NAMESPACE=${env.VAULT_NAMESPACE}",
                            "POSTGRES_PASSWORD=${env.POSTGRES_PASSWORD}",
                            "POSTGRES_NAMESPACE=${env.POSTGRES_NAMESPACE}"
                        ]) {
                            sh 'export ANSIBLE_COW_SELECTION=random; ansible-playbook -v vault_setup.yml'
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                // Aggregate all results into a single archive
                sh '''
                mkdir -p security_results
                cp trivy_*.json security_results/ || true
                cp sbom_*.json security_results/ || true
                cp -R checkov_*/ security_results/ || true
                tar -czvf security_results.tar.gz security_results/
                '''
                archiveArtifacts artifacts: 'security_results.tar.gz', allowEmptyArchive: true
            }
        }
    }
}
