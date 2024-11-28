pipeline {
    agent { label 'Jenkins-Agent' }
    tools {
        jdk 'Java17'
        maven 'Maven3'
    }
    environment {
        JENKINS_API_TOKEN = credentials("JENKINS_API_TOKEN")
    }
    stages{
        
        stage("Cleanup Workspace"){
            steps {
                cleanWs()
            }
        }

        stage("Checkout from SCM"){
            steps {
                git branch: 'main', credentialsId: 'github', url: 'https://github.com/LinuxHunt-Nexus/register-app.git'
            }
        }

        stage("Build Application"){
            steps {
                sh "mvn clean package -DskipTests"
            }
            post {
                success {
                    echo "Now Archiving."
                    archiveArtifacts artifacts: '**/*.war'
                }
            }
       }

       stage("Test Application"){
           steps {
                 sh "mvn test"
           }
       }
       stage('Checkstyle Analysis'){
            steps {
                sh 'mvn checkstyle:checkstyle'
            }
        }
        stage("Trigger Remotely") {
            steps {
                script {
                    def triggerUrl = "ec2-51-20-83-22.eu-north-1.compute.amazonaws.com:8080/job/register-app-pipeline/buildWithParameters?token=${env.JENKINS_API_TOKEN}"
                    echo "Trigger URL: ${triggerUrl}"
                }
            }
        }
    }
}
