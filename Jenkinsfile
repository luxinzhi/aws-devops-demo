pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        ECR_REPO   = '269523617138.dkr.ecr.us-east-1.amazonaws.com/demo-app'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                // Refresh EKS credential once at the beginning
                sh "aws eks update-kubeconfig --name demo-eks --region ${AWS_REGION}"
            }
        }

        stage('Build Image') {
            steps {
                sh """
                docker build -t demo-app:${BUILD_NUMBER} app/
                """
            }
        }

        stage('Push ECR') {
            steps {
                sh """
                aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}
                docker tag demo-app:${BUILD_NUMBER} ${ECR_REPO}:${BUILD_NUMBER}
                docker push ${ECR_REPO}:${BUILD_NUMBER}
                """
            }
        }

        stage('Deploy Green') {

            steps {
                sh """
                sed -i 's/IMAGE_TAG/${BUILD_NUMBER}/g' \
                k8s/green.yaml
                kubectl apply -f k8s/green.yaml

                kubectl rollout status \
                deployment/demo-green \
                --timeout=300s
                """
            }
        }

        stage('Health Check') {
            steps {
                sh """
                # Get pod name labeled app=green
                GREEN_POD=\$(kubectl get pod -l app=green -o jsonpath='{.items[0].metadata.name}')
                # Health probe test inside green pod
                kubectl exec \$GREEN_POD -- curl -f http://localhost/
                echo "Green version health check passed"
                """
            }
        }

        stage('Manual Approval') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    input(
                        message: "Green version health check passed. Confirm switching traffic to Green?",
                        ok: "Confirm Switch"
                    )
                }
            }
        }

        stage('Switch Traffic') {
            steps {
                sh """
                # Modify service selector to route traffic to green deployment
                kubectl patch svc demo-service -p '{"spec":{"selector":{"app":"green"}}}'
                """
            }
        }

        stage('Verify') {
            steps {
                sh """
                sleep 20
                kubectl get svc demo-service
                echo "Traffic switched to Green successfully"
                """
            }
        }
    }

    post {
        failure {
            echo 'Deploy Failed. Rollback To Blue.'
            sh """
            # Roll back traffic to old blue version if any error occurs
            kubectl patch svc demo-service -p '{"spec":{"selector":{"app":"blue"}}}' || true
            """
        }
    }
}
