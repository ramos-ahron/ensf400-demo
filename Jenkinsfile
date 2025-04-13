pipeline {
  agent any
  environment {
    // Default Java Home for Jenkins
    JAVA_HOME = '/usr/lib/jvm/java-11-openjdk'
    PATH = "${JAVA_HOME}/bin:${PATH}"
    // GitHub credentials
    GITHUB_CREDENTIALS = credentials('github-credentials')
    // SonarQube server IP address
    IP_ADDRESS = '10.0.1.34'  // Replace with your actual IP address
  }
  stages {
    // Stage 1: Build the container/application
    stage('Build') {
      steps {
        sh './gradlew clean assemble'
      }
    }
    // Stage 2: Run unit tests
    stage('Unit Tests') {
      steps {
        sh './gradlew test'
      }
      post {
        always {
          junit 'build/test-results/test/*.xml'
        }
      }
    }
    // Stage 3: Static Analysis with SonarQube
    stage('Static Analysis') {
      stages {
        stage('SonarQube Auth') {
          steps {
            script {
              sh 'echo "Waiting for SonarQube to start..." && sleep 80'
              // Remotely change login username and password
              sh """
                curl -X POST "http://\${IP_ADDRESS}:9000/api/users/change_password" \\
                -H "Content-Type: application/x-www-form-urlencoded" \\
                -d "login=admin&previousPassword=admin&password=password" \\
                -u admin:admin
              """
            }
          }
        }
        stage('SonarQube Analysis') {
          agent {
            docker {
              image 'gradle:7.6.1-jdk11'
              reuseNode true  // This ensures the same workspace is used
            }
          }
          steps {
            script {
              sh "./gradlew sonarqube -Dsonar.host.url=http://\${IP_ADDRESS}:9000"
            }
          }
          post {
            success {
              sh 'echo SonarQube results available at http://\${IP_ADDRESS}:9000/?id=Demo'
            }
          }
        }
      }
    }
  }
  post {
    success {
      echo 'Build succeeded! Updating GitHub pull request status.'
      withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
        sh '''
          if [ -n "$CHANGE_ID" ]; then
            curl -s -X POST \\
              -H "Authorization: token ${GITHUB_TOKEN}" \\
              -H "Accept: application/vnd.github.v3+json" \\
              https://api.github.com/repos/${CHANGE_REPOSITORY}/statuses/${GIT_COMMIT} \\
              -d '{"state":"success","context":"jenkins/build","description":"Build succeeded!","target_url":"'${BUILD_URL}'"}'
          fi
        '''
      }
    }
    failure {
      echo 'Build failed! Updating GitHub pull request status.'
      withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
        sh '''
          if [ -n "$CHANGE_ID" ]; then
            curl -s -X POST \\
              -H "Authorization: token ${GITHUB_TOKEN}" \\
              -H "Accept: application/vnd.github.v3+json" \\
              https://api.github.com/repos/${CHANGE_REPOSITORY}/statuses/${GIT_COMMIT} \\
              -d '{"state":"failure","context":"jenkins/build","description":"Build failed!","target_url":"'${BUILD_URL}'"}'
          fi
        '''
      }
    }
  }
}
