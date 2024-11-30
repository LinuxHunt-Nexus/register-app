def COLOR_MAP = [
    'SUCCESS': 'good', 
    'FAILURE': 'danger',
]

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
                    version: "V${env.BUILD_ID}-${env.BUILD_TIMESTAMP}",
                    repository: 'webapp-repo',
                    credentialsId: 'nexus',
                    artifacts: [
                        [artifactId: 'webapp',
                         classifier: '',
                         file: 'webapp/target/webapp.war',
                         type: 'war']
                    	]
                )
	    }
	}
	stage("Build & Push Docker Image") {
            steps {
                script {
		    sh "docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true"
                    docker.withRegistry('',DOCKER_PASS) {
                        docker_image = docker.build "${IMAGE_NAME}"
                    }

                    docker.withRegistry('',DOCKER_PASS) {
                        docker_image.push("${IMAGE_TAG}")
                        docker_image.push('latest')
                    }
                }
            }
        }
	    stage("Trivy DB Update") {
            steps {
                sh "docker run -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --download-db-only"
            }
        }
        stage("Trivy Scan") {
           steps {
               script {
	            sh ('docker run -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image linuxhuntnexus/register-app-pipeline:latest --no-progress --scanners vuln  --exit-code 0 --severity HIGH,CRITICAL --format table')
               }
           }
       }

       stage ('Cleanup Artifacts') {
           steps {
               script {
                    sh "docker rmi ${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker rmi ${IMAGE_NAME}:latest"
               }
          }
       }
        stage("Trigger Remotely") {
            steps {
                script {
                    def triggerUrl = "ec2-51-21-2-55.eu-north-1.compute.amazonaws.com:8080/job/register-app-pipeline/buildWithParameters?token=${env.JENKINS_API_TOKEN}"
                    echo "Trigger URL: ${triggerUrl}"
                }
            }
        }
	    stage("CD Trigger Pipeline") {
            steps {
                script {
                    sh "curl -v -k --user admin:${JENKINS_API_TOKEN} -X POST -H 'cache-control: no-cache' -H 'content-type: application/x-www-form-urlencoded' --data 'IMAGE_TAG=${IMAGE_TAG}' 'http://ec2-51-21-2-55.eu-north-1.compute.amazonaws.com:8080/job/gitops-register-app-cd-pipeline/buildWithParameters?token=gitops-token'"
                }
            }
       }
    }
post {
        always {
            echo 'Slack Notifications.'
            slackSend channel: '#jenkinscicd',
                color: COLOR_MAP[currentBuild.currentResult],
                message: "*${currentBuild.currentResult}:* Job ${env.JOB_NAME} build ${env.BUILD_NUMBER} \n More info at: ${env.BUILD_URL}"
        }
    }
}
