node {
    def server
    def buildInfo
    def rtMaven
 
    stage ('Checkout') {
       checkout scm
    }
 
    stage ('Artifactory configuration') {
        server = Artifactory.server "artif"
        rtMaven = Artifactory.newMavenBuild()
        rtMaven.tool = "mvn" // Tool name from Jenkins configuration
        rtMaven.deployer releaseRepo: 'libs-release-local', snapshotRepo: 'libs-snapshot-local', server: server
        rtMaven.resolver releaseRepo: 'libs-release', snapshotRepo: 'libs-snapshot', server: server
        buildInfo = Artifactory.newBuildInfo()
    }
 
    stage ('build') {
        def out = sh script: './client.sh', returnStdout: true
        rtMaven.run pom: 'api_client/pom.xml', goals: 'clean install', buildInfo: buildInfo
    }
 
    stage ('Publish build info') {
        server.publishBuildInfo buildInfo
    }
}


