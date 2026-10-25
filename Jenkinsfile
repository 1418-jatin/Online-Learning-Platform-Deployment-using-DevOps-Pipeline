pipeline {
    agent any

    environment {
        DOCKERHUB_CRED = credentials('dockerhub-cred')
        EC2_CRED = credentials('ubuntu-cred')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Validate') {
            steps {
                sh '''
                    python3 -m venv .venv
                    . .venv/bin/activate
                    if [ -f requirements.txt ]; then
                        pip install -r requirements.txt
                    else
                        echo "No requirements.txt found, skipping pip install"
                    fi
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build -t 19901418/prt-oct-25th:${BUILD_NUMBER} .
                    docker tag 19901418/prt-oct-25th:${BUILD_NUMBER} 19901418/prt-oct-25th:latest
                '''
            }
        }

        stage('Push Docker Image') {
            steps {
                sh '''
                    echo $DOCKERHUB_CRED_PSW | docker login -u $DOCKERHUB_CRED_USR --password-stdin
                    docker push 19901418/prt-oct-25th:${BUILD_NUMBER}
                    docker push 19901418/prt-oct-25th:latest
                '''
            }
        }

        stage('Deploy to Application Servers') {
            steps {
                sshagent(['ubuntu-cred']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ubuntu@3.142.241.187 \
                        "docker pull 19901418/prt-oct-25th:latest && \
                         docker stop prt-app || true && \
                         docker rm prt-app || true && \
                         docker run -d --name prt-app -p 80:8000 19901418/prt-oct-25th:latest"
                    '''
                }
            }
        }
    }

    post {
        always {
            sh 'docker logout'
        }
    }
}
