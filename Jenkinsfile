pipeline {
    agent { label 'Jenkins-Agent' }
    tools {
        jdk 'Java17'
        maven 'Maven3'
    }
    environment {
        APP_NAME = "register-app-pipeline"
        RELEASE = "1.0.0"
        DOCKER_USER = "linuxhuntnexus"
        DOCKER_PASS = 'dockerhub'
        IMAGE_NAME = "${DOCKER_USER}" + "/" + "${APP_NAME}"
        IMAGE_TAG = "${RELEASE}-${BUILD_NUMBER}"
        
        JENKINS_API_TOKEN = credentials("JENKINS_API_TOKEN")
	NEXUS_TOKEN = credentials("nexus")
        
        scannerHome = tool 'Sonar-Scanner'
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
        stage('Sonar Analysis') {
            steps {
               withSonarQubeEnv('SonarQube') {
                   sh '''
                    ${scannerHome}/bin/sonar-scanner -X \
                    -Dsonar.projectKey=webapp \
                    -Dsonar.projectName=webapp \
                    -Dsonar.projectVersion=1.0 \
                    -Dsonar.sources=server/src/main/java/ \
                    -Dsonar.java.binaries=server/target/classes/ \
                    -Dsonar.junit.reportsPath=server/target/surefire-reports/ \
                    -Dsonar.jacoco.reportsPath=server/target/jacoco.exec \
                    -Dsonar.java.checkstyle.reportPaths=server/target/checkstyle-result.xml
                   '''
              }
            }
        }
        stage("Quality Gate") {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    // Parameter indicates whether to set pipeline to UNSTABLE if Quality Gate fails
                    // true = set pipeline to UNSTABLE, false = don't
                    waitForQualityGate abortPipeline: true, credentialsId: 'jenkins-sonarqube-token'
                }
            }
        }
	stage("UploadArtifact") {
            steps {
                nexusArtifactUploader(
                    nexusVersion: 'nexus3',
                    protocol: 'http',
                    nexusUrl: '13.60.23.143:8081',
                    groupId: 'QA',
                    version: "${env.BUILD_ID}",
                    repository: 'webapp-repo',
                    credentialsId: 'nexus',
                    artifacts: [
                        [artifactId: 'webapp',
                         classifier: '',
                         file: 'target/webapp.war',
                         type: 'war']
                    	]
                )
	    }
	}
	    
    }
}
