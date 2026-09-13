pipeline {
    agent any

    environment {
        // "docker-cred" must be a Jenkins "Username with password" credential
        // (username = Docker Hub ID, password = Docker Hub password or access token)
        DOCKERHUB_CREDENTIALS = credentials('docker-cred')
        DOCKERHUB_USERNAME    = '19901418'
        IMAGE_NAME            = 'my-jenkins-python-app-ci-cd'
        IMAGE_TAG             = "${env.BUILD_NUMBER}"
        FULL_IMAGE            = "${DOCKERHUB_USERNAME}/${IMAGE_NAME}"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/1418-jatin/Online-Learning-Platform-Deployment-using-DevOps-Pipeline.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${FULL_IMAGE}:${IMAGE_TAG} -t ${FULL_IMAGE}:latest ."
            }
        }

        stage('Login to Docker Hub') {
            steps {
                sh "echo \$DOCKERHUB_CREDENTIALS_PSW | docker login -u \$DOCKERHUB_CREDENTIALS_USR --password-stdin"
            }
        }

        stage('Push Docker Image') {
            steps {
                sh "docker push ${FULL_IMAGE}:${IMAGE_TAG}"
                sh "docker push ${FULL_IMAGE}:latest"
            }
        }

        stage('Deploy Container') {
            steps {
                sh """
                    docker rm -f ${IMAGE_NAME} || true
                    docker run -d --name ${IMAGE_NAME} -p 8081:80 ${FULL_IMAGE}:latest
                """
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
        }
        success {
            echo "Build ${IMAGE_TAG} pushed to Docker Hub as ${FULL_IMAGE}:${IMAGE_TAG} and deployed on port 8081."
        }
        failure {
            echo 'Pipeline failed — check the stage logs above.'
        }
    }
}
