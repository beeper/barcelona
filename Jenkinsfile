pipeline {
    agent any
    stages {
        stage('Pop cache') {
            steps {
                sh '[ -d "../$(pwd | rev | cut -f 1 -d/ | rev)-Build" ] && mv "../$(pwd | rev | cut -f 1 -d/ | rev)-Build" ./Build || true'
            }
        }
        stage('Build') {
            steps {
                # sh 'make all'
                sh 'make macos'
            }
        }
        stage('Archive') {
            steps {
                sh 'cp Build/macOS/Build/Products/Release/barcelona-mautrix-macOS darwin-barcelona-mautrix'
                sh 'cp Build/macOS/Build/Products/Release/grapple-macOS darwin-grapple'
                # sh 'cp Build/iOS/Build/Products/Release-iphoneos/barcelona-mautrix-iOS ios-barcelona-mautrix'
                # sh 'cp Build/iOS/Build/Products/Release-iphoneos/grapple-iOS ios-grapple'
                archiveArtifacts artifacts: '*barcelona-mautrix, *grapple'
            }
        }
        stage('Push cache') {
            steps {
                sh 'mv Build "../$(pwd | rev | cut -f 1 -d/ | rev)-Build"'
            }
        }
    }
    post {
        success {
            withCredentials([usernamePassword(credentialsId: 'gitlab-token', passwordVariable: 'TOKEN', usernameVariable: '')]) {
                sh 'curl -X POST --fail -F token=${TOKEN} -F ref=refs/heads/beta https://gitlab.com/api/v4/projects/27603475/trigger/pipeline > /dev/null'
            }
        }
    }
}
