#!groovy​

pipeline {

    //Using Anka for parallel builds
    agent {
        node {
            label 'ios-agent'
            customWorkspace '/Users/anka/workspace/app'
        }
    }

    environment {
        FASTLANE_PASSWORD = credentials('fastlanePassword')
        MATCH_PASSWORD = credentials('matchPassword')
        NO_PROMPT = "1"
    }

    options {
        ansiColor('xterm')
        parallelsAlwaysFailFast()
        timeout(time: 2, unit: 'HOURS')
        buildDiscarder(
            logRotator(
                numToKeepStr: '10', 
                artifactNumToKeepStr: '10', 
                daysToKeepStr: '7'
            )
        )
    }

    stages {
        stage('Clone Repo') {
            steps {
                checkout scm
            }
        }

        stage('Build & Install') {
            steps {
                sh 'make install'
            }
        }

        stage('Run Lint') {
            steps {
                sh 'make lint'
            }
        }

        stage('Unit Tests') {
            steps {
                sh 'make wipe'
                sh 'make test'
            }
            post {
                success {
                    junit 'fastlane/test_output/report.junit'
                    publishHTML target: [
                        allowMissing: false, 
                        alwaysLinkToLastBuild: false, 
                        keepAll: true, 
                        reportDir: 'fastlane/xcov_report', 
                        reportFiles: 'index.html', 
                        reportName: 'Unit Tests - Coverage Report'
                    ]
                }
            }
        }

        stage('UI Tests') {
            steps {
                retry(2) {
                    sh 'make wipe'
                    sh 'make ui_test'
                }
            }
            post {
                success {
                    junit 'fastlane/test_output/report.junit'
                    publishHTML target: [
                        allowMissing: false, 
                        alwaysLinkToLastBuild: false, 
                        keepAll: true, 
                        reportDir: 'fastlane/xcov_report', 
                        reportFiles: 'index.html', 
                        reportName: 'UI Tests - Coverage Report'
                    ]
                }
            }
        }

        stage('Modularised Feature Integration Test') {
            steps {
                retry(2) {
                    sh 'make wipe'
                    sh 'make fastlane_some_feature_integration_tests'
                }
            }
            post {
                aborted {
                    echo 'Does not post to slack if it was intentionally aborted'
                }
                failure {
                    script {
                        slackSend channel: '#some-feature-channel',
                                    color: 'danger',
                                    baseUrl: "https://some-workspace.slack.com/services/hooks/jenkins-ci/",
                                    teamDomain: "some-workspace",
                                    token: "someToken",
                                    message: ":newalert: @here iOS Pipeline is Broken :newalert:"
                    }
                }
            }
        }

        stage('Deploy to Alpha') {
            when {
                expression { return env.BRANCH_NAME =~ /master|^release-.*/ }
            }
            environment {
                FASTLANE_USER = credentials('testFlightUser')
                FASTLANE_PASSWORD = credentials('testFlightPassword')
            }
            steps {
                lock('ios-release-alpha-lock') {
                    sh 'make release_alpha'
                }
            }
        }

        //if you want to send to testflight
        stage('New Testflight Version') {
            environment {
                FASTLANE_USER = credentials('testflightUser')
                FASTLANE_PASSWORD = credentials('testflightPassword')
            }
            steps {
                sh 'make new_swimlane_testflight'
            }
        }
    }

    post {
        aborted {
          echo 'Does not post to slack if it was intentionally aborted'
        }
        failure {
            script {
                if (env.BRANCH_NAME == 'master') {
                    slackSend channel: '#app-ios-devs',
                            color: 'danger',
                            baseUrl: "https://some-workspace.slack.com/services/hooks/jenkins-ci/",
                            teamDomain: "some-workspace",
                            token: "someToken",
                            message: ":newalert: @here iOS Pipeline is Broken :newalert:"
                }
            }
        }
        fixed {
            script {
                if (env.BRANCH_NAME == 'master') {
                    slackSend channel: '#app-ios-devs',
                            color: 'good',
                            baseUrl: "https://some-workspace.slack.com/services/hooks/jenkins-ci/",
                            teamDomain: "some-workspace",
                            token: "someToken",
                            message: ":green_heart: iOS Pipeline is Back to Green :green_heart:"
                }
            }
        }
        success {
          sh """
            echo 'Some success action'
          """
        }
    }
}
