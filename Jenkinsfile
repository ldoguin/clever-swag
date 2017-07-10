node {
    def server
    def buildInfo
    def rtMaven
    
    stage ('Build') {
        git url: 'https://github.com/ldoguin/clever-swag.git'
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

    stage ('Publish Static Doc') {
        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'ldoguinGithub',
                usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD']]) {
            git url: "https://$USERNAME:$PASSWORD@github.com/ldoguin/api-doc",
            branch: 'master'
            sh 'cp html_site/index.html .'
            sh 'git config --global user.email "jenkins@clever-cloud.com"'
            sh 'git config --global user.name "Jenkins Bot"'
            sh 'git add index.html'
            sh 'git commit -m"update documentation"'
            sh 'git push origin master'
        }  
    }
}


