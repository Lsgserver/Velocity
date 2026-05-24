pipeline {
    agent any

    environment {
        REGISTRY   = 'docker.lsgserver.dev'
        IMAGE_NAME = 'velocitymc'
        IMAGE_TAG  = "${env.BUILD_NUMBER}"
        FULL_IMAGE = "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
    }

    stages {

        // No Checkout stage needed — Jenkins already cloned the repo
        // because this Jenkinsfile IS in the repo (Pipeline from SCM).

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${FULL_IMAGE}", ".")
                }
            }
        }

        stage('Push to Registry') {
            steps {
                script {
                    docker.withRegistry("http://${REGISTRY}") {
                        def img = docker.image("${FULL_IMAGE}")
                        img.push()
                        img.push('latest')
                    }
                }
            }
        }

    }

    post {
        success {
            echo "✅ Built and pushed: ${FULL_IMAGE}"
        }
        failure {
            echo "❌ Build failed — check logs above."
        }
        always {
            sh 'docker image prune -f'
        }
    }
}
