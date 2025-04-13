pipeline {
  agent any

  environment {
    JAVA_HOME = '/usr/lib/jvm/java-11-openjdk'
    PATH = "${JAVA_HOME}/bin:${PATH}"
    SONAR_HOST_URL = 'https://ideal-space-goggles-699xwwqvjj4ghxv6v-9000.app.github.dev'
    SONAR_TOKEN = credentials('sonar-token') // Store your SonarQube token in Jenkins credentials
  }

  stages {
    stage('Build') {
      steps {
        sh './gradlew clean assemble'
      }
    }

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

    stage('Static Analysis') {
      steps {
        script {
          // Verify SonarQube is accessible (no need for wait loop in Codespaces)
          def status = sh(script: "curl -s -f ${SONAR_HOST_URL}/api/system/status", returnStatus: true)
          if (status != 0) {
            error("SonarQube is not accessible at ${SONAR_HOST_URL}")
          }
        }
        sh "./gradlew sonarqube \
            -Dsonar.projectKey=my-project \
            -Dsonar.projectName='My Project' \
            -Dsonar.host.url=${SONAR_HOST_URL} \
            -Dsonar.login=${SONAR_TOKEN}"
      }
    }
  }

  post {
    success {
      echo 'Build succeeded! Updating GitHub status...'
      githubStatusUpdate()
    }
    failure {
      echo 'Build failed! Updating GitHub status...'
      githubStatusUpdate()
    }
  }
}

// Helper function for GitHub status updates
def githubStatusUpdate() {
  withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
    sh '''
      if [ -n "$CHANGE_ID" ]; then
        curl -s -X POST \
          -H "Authorization: token ${GITHUB_TOKEN}" \
          -H "Accept: application/vnd.github.v3+json" \
          https://api.github.com/repos/${CHANGE_REPOSITORY}/statuses/${GIT_COMMIT} \
          -d '{"state":"'${currentBuild.result == 'SUCCESS' ? 'success' : 'failure'}'","context":"jenkins/build","description":"Build '${currentBuild.result}'","target_url":"'${BUILD_URL}'"}'
      fi
    '''
  }
}
