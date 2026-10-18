pipeline {
    agent { label 'linux agent' }

    environment {
        IMAGE_NAME = "19901418/my-jenkins-python-app-ci-cd"
        IMAGE_TAG  = "latest"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git url: 'https://github.com/1418-jatin/Online-Learning-Platform-Deployment-using-DevOps-Pipeline.git', branch: 'main'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .'
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-cred',
                                                 usernameVariable: 'DOCKER_USER',
                                                 passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                    '''
                }
            }
        }

        stage('Deploy Container') {
            steps {
                sh '''
                docker rm -f online-learning || true
                docker run -dit --name online-learning -p 9090:80 ${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }
    }

    triggers {
        githubPush()
    }
}
