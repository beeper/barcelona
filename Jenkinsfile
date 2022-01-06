pipeline {
    agent any
    stages {
        stage('Pop cache') {
            steps {
                sh '[ -d "../$(pwd | rev | cut -f 1 -d/ | rev)-Build" ] && mv "../$(pwd | rev | cut -f 1 -d/ | rev)-Build" ./Build || true'
            }
        }
        stage('Prepare') {
            steps {
                sh 'make refresh'
            }
        }
        stage('Build') {
            steps {
                parallel(
                    macos: {
                        sh 'make macos'
                    },
                    ios: {
                        sh 'make ios'
                    }
                )
            }
        }
        stage('Archive') {
            steps {
                sh 'cp Build/macOS/Build/Products/Release/barcelona-mautrix-macOS darwin-barcelona-mautrix'
                sh 'cp Build/macOS/Build/Products/Release/grapple-macOS darwin-grapple'
                sh 'cp Build/iOS/Build/Products/Release-iphoneos/barcelona-mautrix-iOS ios-barcelona-mautrix'
                sh 'cp Build/iOS/Build/Products/Release-iphoneos/grapple-iOS ios-grapple'
                archiveArtifacts artifacts: '*barcelona-mautrix, *grapple'
            }
        }
        stage('Push cache') {
            steps {
                sh 'mv Build "../$(pwd | rev | cut -f 1 -d/ | rev)-Build"'
            }
        }
    }
}
