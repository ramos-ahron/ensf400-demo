pipeline {
  agent any

  environment {
    // Default Java Home for Jenkins
    JAVA_HOME = '/usr/lib/jvm/java-11-openjdk'
    PATH = "${JAVA_HOME}/bin:${PATH}"
    // GitHub credentials
    GITHUB_CREDENTIALS = credentials('github-credentials')
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
      steps {
        sh '''
          max_attempts=30
          attempt=0
          until curl -s -f http://sonarqube:9000/api/system/status > /dev/null || [ $attempt -eq $max_attempts ]
          do
            echo "Waiting for SonarQube to be available... ($(( attempt++ ))/$max_attempts)"
            sleep 10
          done
          if [ $attempt -eq $max_attempts ]; then
            echo "SonarQube did not become available in time"
            exit 1
          fi
        '''
        sh './gradlew sonarqube \
            -Dsonar.projectKey=my-project \
            -Dsonar.projectName="My Project" \
            -Dsonar.host.url=http://sonarqube:9000 \
            -Dsonar.login="admin" \
            -Dsonar.password="ensf400"'
      }
    }
  }

  post {
    success {
      echo 'Build succeeded! Updating GitHub pull request status.'
      withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
        sh '''
          if [ -n "$CHANGE_ID" ]; then
            curl -s -X POST \
              -H "Authorization: token ${GITHUB_TOKEN}" \
              -H "Accept: application/vnd.github.v3+json" \
              https://api.github.com/repos/${CHANGE_REPOSITORY}/statuses/${GIT_COMMIT} \
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
            curl -s -X POST \
              -H "Authorization: token ${GITHUB_TOKEN}" \
              -H "Accept: application/vnd.github.v3+json" \
              https://api.github.com/repos/${CHANGE_REPOSITORY}/statuses/${GIT_COMMIT} \
              -d '{"state":"failure","context":"jenkins/build","description":"Build failed!","target_url":"'${BUILD_URL}'"}'
          fi
        '''
      }
    }
  }
}
