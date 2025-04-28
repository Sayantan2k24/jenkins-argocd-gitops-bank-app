pipeline {
    agent any
    parameters {
        // prompt the user for this value when pipeline executes / at runtime
        string(name: 'DOCKER_TAG', defaultValue: 'latest', description: 'Docker Image Tag')
        // to use it --> ${params.DOCKER_TAG}
    }
    
    tools {
        maven 'maven3'
    }
    
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        DOCKERHUB_USERNAME = 'sayantan2k21'
        APP_NAME = "bankapp"
        IMAGE_NAME = "${DOCKERHUB_USERNAME}/${APP_NAME}"
    }

    stages {
        stage('Cleanup Workspace') {
            steps {
                // including the groovy script in the declarative pipeline
                script {
                    cleanWs()
                }
            }
        }
        stage('Git Checkout') {
            steps {
                git branch: 'main', credentialsId: 'git-cred', url: 'https://github.com/Sayantan2k24/jenkins-argocd-gitops-bank-app-CI.git'
            }
        }
        stage('Compile') {
            steps {
                sh "mvn compile"
            }
        }
        stage('test') {
            steps {
                sh "mvn test -DskipTests=true" // skip the test cases
            }
        }
        
        stage('File System Scan') {
            steps {
                sh "trivy fs --format table -o fs.html ."
            }
        }
        
        stage('Sonaqube Analysis') {
            steps {
                withSonarQubeEnv('sonar') {
                    
                    sh '''$SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=bankapp \
                        -Dsonar.projectKey=bankapp \
                        -Dsonar.java.binaries=target/classes'''
                }

            }
        }
        stage('Build & Publish') {
            steps {
                withMaven(globalMavenSettingsConfig: 'maven-setting-bankapp', jdk: '', maven: 'maven3', mavenSettingsConfig: '', traceability: true) {
                // steps to publish artificat to nexus
                    sh "mvn deploy -DskipTests=true"
                }
            }
        }
        // next docker stage
        stage('Docker Build & Tag') {
            steps {
                script {
                    echo "Building Docker Image with Tag: ${params.DOCKER_TAG}"
                    sh "docker build -t ${IMAGE_NAME}:${params.DOCKER_TAG} ."
                    sh "docker tag ${IMAGE_NAME}:${params.DOCKER_TAG} ${IMAGE_NAME}:latest"

                }
            }
        }
        // scan the docker image
        stage('Docker Image Scan') {
            steps {
                sh "trivy image --format table -o dockerimage.html ${IMAGE_NAME}:${params.DOCKER_TAG}"
            }
        }
        
        // once scan successful, push docker image into docker hub registry
        stage('Push Docker Image') {
            steps{
                // wrap it inside a funciton
                withCredentials([usernamePassword(credentialsId: 'docker-cred', passwordVariable: 'pass', usernameVariable: 'user')]) {
                    // use shell commands
                    sh "echo $pass | docker login -u $user --password-stdin "
                    sh "docker push ${IMAGE_NAME}:${params.DOCKER_TAG}"
                    sh "docker push ${IMAGE_NAME}:latest"
                }
            }
        }
        
        // delete the docker images locally
        stage('Delete Docker Image Locally') {
            steps {
                sh "docker rmi ${IMAGE_NAME}:${params.DOCKER_TAG}"
                // sh "docker rmi ${IMAGE_NAME}:latest"
            }
        }
        
        stage('Updating Kubernetes Deployment File') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'git-cred', passwordVariable: 'pass', usernameVariable: 'user')]) {
                        sh """
                            git clone https://${user}:${pass}@github.com/Sayantan2k24/gitops-BankApp-CD.git
                            cd gitops-BankApp-CD
                            ls -l bankapp
                    
                            repo_dir=\$(pwd)
                            cat \$repo_dir/bankapp/bankapp-ds.yml
                            sed -i "s|image: ${IMAGE_NAME}:.*|image: ${IMAGE_NAME}:${params.DOCKER_TAG}|g" \$repo_dir/bankapp/bankapp-ds.yml
                        """

                        
                        // Confirm the changes
                        sh """
                            echo "Updated YAML file contents:"
                            cd gitops-BankApp-CD
                            repo_dir=\$(pwd)
                            cat \$repo_dir/bankapp/bankapp-ds.yml
                        """
                        
                        // Configure Git for committing changes and pushing into GitHub
                        sh '''
                            cd gitops-BankApp-CD
                            git config user.email "sayantansamanta12102001@gmail.com"
                            git config user.name "Sayantan"
                        '''
                        
                        // Commit and push the Updated YAML file back to the CD repository
                        sh """
                            cd gitops-BankApp-CD
                            ls
                            git add bankapp/bankapp-ds.yml
                            git commit -m "Updated image tag to ${params.DOCKER_TAG}"
                            git push origin main
                        """
                    
                    }
       
                }
            }
        }
    }
}