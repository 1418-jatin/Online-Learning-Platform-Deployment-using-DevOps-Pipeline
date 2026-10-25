pipeline {
    agent any

    environment {
        DOCKER_REPO  = "19901418/prt-oct-25th"
        DOCKER_IMAGE = "${DOCKER_REPO}:${BUILD_NUMBER}"
    }

    stages {
        // Jenkins already checks out the repo (Declarative: Checkout SCM)

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${DOCKER_IMAGE} .'
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-cred',
                                                 usernameVariable: 'DOCKER_USER',
                                                 passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${DOCKER_IMAGE}
                        docker tag ${DOCKER_IMAGE} ${DOCKER_REPO}:latest
                        docker push ${DOCKER_REPO}:latest
                    '''
                }
            }
        }
    }

    post {
        always {
            sh '''
                docker logout || true
                docker rmi ${DOCKER_IMAGE} ${DOCKER_REPO}:latest || true
            '''
        }
    }
}
