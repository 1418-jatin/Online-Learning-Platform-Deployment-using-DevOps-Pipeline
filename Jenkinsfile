pipeline {
    agent any

    options {
        skipDefaultCheckout(true)      // checkout is done explicitly in the first stage
        disableConcurrentBuilds()
    }

    // Triggered by the GitHub webhook (push events)
    triggers {
        githubPush()
    }

    environment {
        DOCKER_REPO  = "19901418/prt-oct-25th"
        DOCKER_IMAGE = "${DOCKER_REPO}:${BUILD_NUMBER}"

        // Public IPs of the two application servers (Jenkins reaches them over the internet)
        APP_SERVERS  = "3.142.241.187 3.148.215.92"

        // PostgreSQL server (public IP 3.145.56.120). The app containers on the app servers connect to it
        // inside PRT-VPC, so use the DB server's PRIVATE IP here (find it with: hostname -I on the DB server)
        DB_HOST      = "10.0.1.209"
        DB_PORT      = "5432"
        DB_NAME      = "olp_db"
        DB_USER      = "olp_user"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'git log -1 --pretty="Commit: %h - %s (%an)"'
            }
        }

        stage('Build & Validate') {
            steps {
                sh '''
                    python3 -m venv .venv
                    . .venv/bin/activate
                    pip install --quiet -r requirements.txt

                    # syntax check
                    python -m py_compile app.py

                    # smoke test of the application (home page and health endpoint)
                    python -c "import app; c = app.app.test_client(); assert c.get('/').status_code == 200; assert c.get('/health').status_code == 200; print('validation passed')"

                    # the Dockerfile must exist
                    test -f Dockerfile
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${DOCKER_IMAGE} .'
            }
        }

        stage('Tag & Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-cred',
                                                 usernameVariable: 'DOCKER_USER',
                                                 passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker tag ${DOCKER_IMAGE} ${DOCKER_REPO}:latest
                        docker push ${DOCKER_IMAGE}
                        docker push ${DOCKER_REPO}:latest
                    '''
                }
            }
        }

        // Rolling deployment: one server at a time, so the site stays up on the other one
        stage('Deploy to Application Servers') {
            steps {
                withCredentials([
                    sshUserPrivateKey(credentialsId: 'app-server-ssh', keyFileVariable: 'SSH_KEY'),
                    string(credentialsId: 'olp-db-password', variable: 'DB_PASSWORD')
                ]) {
                    sh '''
                        SSH_OPTS="-i $SSH_KEY -o StrictHostKeyChecking=no -o ConnectTimeout=15"

                        for SERVER in ${APP_SERVERS}; do
                            echo "===== Deploying ${DOCKER_IMAGE} to ${SERVER} ====="

                            # database settings (the password goes over stdin, never on a command line)
                            printf 'DB_HOST=%s\\nDB_PORT=%s\\nDB_NAME=%s\\nDB_USER=%s\\nDB_PASSWORD=%s\\n' \
                                "$DB_HOST" "$DB_PORT" "$DB_NAME" "$DB_USER" "$DB_PASSWORD" | \
                                ssh $SSH_OPTS ubuntu@${SERVER} "umask 077; cat > ~/olp.env"

                            # pull the new image, stop and remove the old container, start the new one
                            ssh $SSH_OPTS ubuntu@${SERVER} "
                                set -e
                                docker pull ${DOCKER_IMAGE}
                                docker rm -f olp-app || true
                                docker run -d --name olp-app --restart unless-stopped --env-file ~/olp.env -p 127.0.0.1:5000:5000 ${DOCKER_IMAGE}
                                docker image prune -f
                            "

                            # wait until this server answers through Nginx before touching the next one
                            OK=0
                            for i in $(seq 1 12); do
                                if ssh $SSH_OPTS ubuntu@${SERVER} "curl -fsS http://localhost/health" > /dev/null; then
                                    OK=1
                                    break
                                fi
                                sleep 5
                            done
                            if [ "$OK" != "1" ]; then
                                echo "ERROR: ${SERVER} did not become healthy"
                                exit 1
                            fi
                        done
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ubuntu-cred', keyFileVariable: 'SSH_KEY')]) {
                    sh '''
                        SSH_OPTS="-i $SSH_KEY -o StrictHostKeyChecking=no -o ConnectTimeout=15"

                        for SERVER in ${APP_SERVERS}; do
                            echo "===== Verifying ${SERVER} ====="

                            # the container is running the image we just built
                            RUNNING_IMAGE=$(ssh $SSH_OPTS ubuntu@${SERVER} "docker inspect -f '{{.Config.Image}}' olp-app")
                            STATE=$(ssh $SSH_OPTS ubuntu@${SERVER} "docker inspect -f '{{.State.Status}}' olp-app")
                            echo "image=${RUNNING_IMAGE} state=${STATE}"
                            [ "$RUNNING_IMAGE" = "${DOCKER_IMAGE}" ] || { echo "ERROR: wrong image on ${SERVER}"; exit 1; }
                            [ "$STATE" = "running" ] || { echo "ERROR: container not running on ${SERVER}"; exit 1; }

                            # application, Nginx and database all respond
                            ssh $SSH_OPTS ubuntu@${SERVER} "curl -fsS http://localhost/health && echo && curl -fsS http://localhost/db-check && echo"
                        done

                        echo "All application servers are running ${DOCKER_IMAGE}"
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
        success {
            echo "Deployment of ${DOCKER_IMAGE} succeeded"
        }
        failure {
            echo "Pipeline failed - check the stage that is marked red"
        }
    }
}
