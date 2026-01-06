pipeline {
    agent any

    environment {
        GCP_PROJECT_ID = 'hrgf-gcp-devops-project'
        GCP_REGION     = 'us-central1'
        GKE_CLUSTER    = 'hrgf-gke-cluster'
        GKE_ZONE       = 'us-central1-a'
        ARTIFACT_REPO  = 'hrgf-app'
        IMAGE_NAME     = 'hrgf-app'
        IMAGE_TAG      = "${env.BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Authenticate to GCP') {
            steps {
                withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh '''
                      gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
                      gcloud config set project $GCP_PROJECT_ID
                    '''
                }
            }
        }

        stage('Configure Docker') {
            steps {
                sh '''
                  gcloud auth configure-docker ${GCP_REGION}-docker.pkg.dev --quiet
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                  IMAGE_URI=${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${ARTIFACT_REPO}/${IMAGE_NAME}

                  docker build -f docker/Dockerfile \
                    -t ${IMAGE_URI}:${IMAGE_TAG} .
                '''
            }
        }

        stage('Trivy Scan') {
            steps {
                sh '''
                  trivy image --severity HIGH,CRITICAL \
                    ${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${ARTIFACT_REPO}/${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }

        stage('Push Image') {
            steps {
                sh '''
                  IMAGE_URI=${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${ARTIFACT_REPO}/${IMAGE_NAME}
                  docker push ${IMAGE_URI}:${IMAGE_TAG}
                '''
            }
        }

        stage('Deploy to GKE with Helm') {
            steps {
                sh '''
                  gcloud container clusters get-credentials \
                    $GKE_CLUSTER \
                    --zone $GKE_ZONE \
                    --project $GCP_PROJECT_ID

                  helm upgrade --install hrgf-app helm/hrgf-app \
                    --set image.repository=${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${ARTIFACT_REPO}/${IMAGE_NAME} \
                    --set image.tag=${IMAGE_TAG} \
                    --wait \
                    --timeout 5m
                '''
            }
        }
    }

    post {
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Pipeline failed'
        }
    }
}
