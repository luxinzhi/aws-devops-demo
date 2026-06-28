pipeline {

    agent any

    environment {

        AWS_REGION = "us-east-1"
        CLUSTER_NAME = "demo-eks"

        ECR_REPO = "269523617138.dkr.ecr.us-east-1.amazonaws.com/demo-app"

        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Prepare Kubernetes') {
            steps {

                sh """
                    aws eks update-kubeconfig \
                    --region ${AWS_REGION} \
                    --name ${CLUSTER_NAME}

                    kubectl get nodes
                """

            }
        }

        stage('Build Docker Image') {

            steps {

                sh """

                    docker build \
                    -t demo-app:${IMAGE_TAG} \
                    app/

                """

            }

        }

        stage('Login ECR & Push Image') {

            steps {

                sh """

                aws ecr get-login-password \
                --region ${AWS_REGION} \
                | docker login \
                --username AWS \
                --password-stdin ${ECR_REPO}

                docker tag demo-app:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}

                docker push ${ECR_REPO}:${IMAGE_TAG}

                """

            }

        }

        stage('Deploy Green') {

            steps {

                sh """

                cp k8s/green.yaml /tmp/green.yaml

                sed -i 's/IMAGE_TAG/${IMAGE_TAG}/g' /tmp/green.yaml

                kubectl apply -f /tmp/green.yaml

                kubectl rollout status deployment/demo-green --timeout=300s

                """

            }

        }

        stage('Wait Green Ready') {

            steps {

                sh """

                kubectl wait \
                --for=condition=Ready \
                pod \
                -l app=green \
                --timeout=180s

                """

            }

        }

        stage('Health Check') {

            steps {

                sh """

                GREEN_POD=$(kubectl get pod \
                -l app=green \
                -o jsonpath='{.items[0].metadata.name}')

                kubectl exec $GREEN_POD -- wget -qO- http://localhost/

                echo "Green version health check passed."

                """

            }

        }

        stage('Manual Approval') {

            steps {

                timeout(time: 5, unit: 'MINUTES') {

                    input(

                        message: "Green deployment succeeded. Switch traffic to Green?",

                        ok: "Switch"

                    )

                }

            }

        }

        stage('Switch Traffic') {

            steps {

                sh """

                kubectl patch svc demo-service \
                -p '{"spec":{"selector":{"app":"green"}}}'

                sleep 15

                """

            }

        }

        stage('Verify Service') {

            steps {

                sh """

                kubectl get svc demo-service

                kubectl get endpoints demo-service

                kubectl get pods -o wide

                echo "Traffic switched successfully."

                """

            }

        }

    }

    post {

        success {

            echo "Deployment completed successfully."

        }

        failure {

            echo "Deployment failed."

            sh """

            kubectl patch svc demo-service \
            -p '{"spec":{"selector":{"app":"blue"}}}' || true

            """

        }

        aborted {

            echo "Deployment aborted."

            sh """

            kubectl patch svc demo-service \
            -p '{"spec":{"selector":{"app":"blue"}}}' || true

            """

        }

        always {

            sh """

            docker image prune -af || true

            docker container prune -f || true

            """

        }

    }

}
