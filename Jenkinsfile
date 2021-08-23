pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                parallel(
                    macos: {
                        sh 'make mautrix-macos'
                        sh 'make grapple-macos'
                    },
                    ios: {
                        sh 'make mautrix-ios'
			sh 'make grapple-ios'
                    }
                )
            }
        }
        stage('Archive') {
            steps {
                sh 'cp Build/macOS/Build/Products/Debug/barcelona-mautrix darwin-barcelona-mautrix'
                sh 'cp Build/macOS/Build/Products/Debug/grapple darwin-grapple'
                sh 'cp Build/iOS/Build/Products/Debug-iphoneos/barcelona-mautrix ios-barcelona-mautrix'
                archiveArtifacts artifacts: '*barcelona-mautrix, darwin-grapple'
            }
        }
    }
}
