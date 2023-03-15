pipeline {
    agent any
    tools{
        nodejs '16.16.0'
        maven '3.6.3'
    }

    environment{
        dockercreds=credentials('docker_id')
    }

    stages {
        stage('build spring app') {
            steps {
                dir('backend'){
                  sh 'mvn clean'
                  sh 'mvn install -DskipTests'
                }
            }
        }

        stage('build frrontend and backend') {
            steps {
                dir('backend'){
                    sh 'docke build -t backend-sb:v$BUILD_NUMBER .'
                }
                    
                dir('frontend'){
                    sh 'docke build -t frontend:v$BUILD_NUMBER .'
                }
            }
        }

        stage('push image to docker hub') {
            steps {
                sh 'echo $dockercreds_PSW | docker login -u $dockercreds_USR --password-stdin'
                sh 'docker push courageoi/backend-sb:$BUILD_NUMBER'
                sh 'docker push courageoi/frontend:$BUILD_NUMBER'
            }
        }

        stage ('final clean up'){
            steps{
                sh 'docker logout'
            }
        }


    }
}