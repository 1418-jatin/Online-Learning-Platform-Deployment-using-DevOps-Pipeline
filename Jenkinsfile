pipeline {
    agent any

    environment {
        DOCKERHUB_CRED = credentials('dockerhub-cred')
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Install System Dependencies') {
            steps {
                sh '''
                sudo apt-get update
                sudo apt-get install -y python3-dev libjpeg-dev zlib1g-dev libfreetype6-dev \
                    liblcms2-dev libopenjp2-7-dev libtiff5-dev libwebp-dev pkg-config
                '''
            }
        }

        stage('Build & Validate') {
            steps {
                sh '''
                python3 -m venv .venv
                . .venv/bin/activate
                if [ -f requirements.txt ]; then
                    pip install --upgrade pip setuptools wheel
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
                docker build -t $DOCKERHUB_CRED_USR/prt-oct-25th:latest .
                '''
            }
        }

        stage('Push Docker Image') {
            steps {
                sh '''
                echo $DOCKERHUB_CRED_PSW | docker login -u $DOCKERHUB_CRED_USR --password-stdin
                docker push $DOCKERHUB_CRED_USR/prt-oct-25th:latest
                '''
            }
        }

        stage('Deploy to Application Servers') {
            steps {
                sh '''
                # Example deployment step
                docker-compose down
                docker-compose up -d
                '''
            }
        }
    }

    post {
        always {
            sh 'docker logout'
        }
    }
}
