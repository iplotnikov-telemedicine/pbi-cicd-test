#!groovy

import java.util.regex.Matcher
import java.util.regex.Pattern

properties([
    buildDiscarder(logRotator(
        daysToKeepStr: '180',
        numToKeepStr: '180',
        artifactDaysToKeepStr: '180',
        artifactNumToKeepStr: '180'
    )),
    disableConcurrentBuilds() // This limits build concurrency to 1 per branch
])

String azureReposPowerBIReports="https://credentially@dev.azure.com/credentially/PowerBI/_git/Reports"

node('jenkins-build-agent') {
    stage('Get utils') {
        checkout scm: [$class: 'GitSCM',
                    userRemoteConfigs:
                        [[url: 'https://github.com/Credentially/jenkins-pipeline.git',
                            credentialsId: 'github-authentication']],
                    branches: [[name: 'tags/v1.13.0']]],
                    poll: false

        pipeline = load "jenkinsPipelineUtils.groovy"
    }

    pipeline.runPipeline() {
        if (env.BRANCH_NAME == 'develop' || env.BRANCH_NAME.startsWith('hotfix/') || env.BRANCH_NAME.startsWith('release/')) {
            stage('Checkout') {
                git branch: pipeline.getBranchName(),
                        credentialsId: 'github-authentication',
                        url: 'https://github.com/Credentially/power-bi-reports.git'
            }

            stage("Copy ${env.BRANCH_NAME} branch from Github to Azure Repos") {
                pipeline.gitAzure("remote set-url origin $azureReposPowerBIReports")
                pipeline.gitAzure("push origin ${env.BRANCH_NAME}")
            }
        }

        // Check tags
        if (env.TAG_NAME ==~ /^v(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/) {
            stage('Checkout') {
                checkout scm: [$class: 'GitSCM',
                            userRemoteConfigs:
                                [[url: 'https://github.com/Credentially/power-bi-reports.git',
                                    credentialsId: 'github-authentication']],
                            branches: [[name: "tags/${env.TAG_NAME}"]]],
                            poll: false
            }

            stage("Create ${env.TAG_NAME} branch on Azure Repos from ${env.TAG_NAME} tag on Github") {
                pipeline.gitAzure("remote set-url origin $azureReposPowerBIReports")
                String version = pipeline.getVersion()
                pipeline.gitAzure("checkout -b $version ${env.TAG_NAME}")
                pipeline.gitAzure("push origin $version")
            }
        }
        jiraSendBuildInfo()
    }
}
