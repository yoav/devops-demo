import org.artifactory.build.Artifact
import org.artifactory.build.BuildRun
import org.artifactory.build.Dependency
import org.artifactory.build.DetailedBuildRun
import org.artifactory.build.Module
import org.artifactory.build.ReleaseStatus
import org.artifactory.common.StatusHolder
import org.artifactory.exception.CancelException
import org.artifactory.fs.FileInfo
import org.artifactory.repo.RepoPath
import org.artifactory.util.StringInputStream
import static groovy.xml.XmlUtil.serialize
import static org.artifactory.repo.RepoPathFactory.create


promotions {

    cloudPromote(users: "jenkins", params: ['deploy-env': 'staging', targetRepository: 'cloud-deploy-local']) { buildName, buildNumber, params ->
        log.info 'Promoting build: ' + buildName + '/' + buildNumber

        def properties = [:]
        String val = getStringProperty(params, 'deploy-env', true)
        if (val) {
            properties['deploy.env'] = val
        }
        String targetRepo = getStringProperty(params, 'targetRepository', true)

        if (!params || !buildNumber || properties.isEmpty()) {
            message = 'Please supply a build number parameter and a deploy.env parameter .'
            log.error message
            status = 400
            throw new CancelException(message, status)
        }

        List<BuildRun> buildsRun = builds.getBuilds(buildName, buildNumber, null)
        if (buildsRun.size() > 1) {
            cancelPromotion('Found two matching builds to promote, please provide build start time', null, 409)
        }

        def buildRun = buildsRun[0]
        if (buildRun == null) {
            cancelPromotion("Build $buildName/$buildNumber was not found, cancelling promotion", null, 409)
        }
        Set<FileInfo> stageArtifactsList = builds.getArtifactFiles(buildRun)
        List<RepoPath> targetList = []
        StatusHolder cstatus
        stageArtifactsList.each { item ->
            RepoPath repoPath = item.getRepoPath()
            if(repoPath.getPath().endsWith('.war')){
                RepoPath targetRepoPath = create(targetRepo, repoPath.getPath())
                targetList << targetRepoPath
                if (!repositories.exists(targetRepoPath)) {
                    cstatus = repositories.copy(repoPath, targetRepoPath)
                    if (cstatus.isError()) {
                        targetList.each { repositories.delete(it) }
                        message = "Copy of $repoPath failed ${cstatus.getLastError().getMessage()}"
                        cancelPromotion(message, cstatus.getLastError().getException(), 500)
                    }

                }
                properties.each { prop ->
                    repositories.setProperty(targetRepoPath, prop.key, prop.value)
                }

            }
        }


    }

}

private String getStringProperty(params, pName, mandatory) {
    # println "**** ENV=$params"
    def vals = params[pName]
    def val = vals == null ? null : vals[0].toString()
    if (mandatory && val == null) {
        cancelPromotion("$pName is a mandatory paramater", null, 400)
    }
    return val
}

def cancelPromotion(message, Throwable cause, int errorLevel) {
    log.warn message
    throw new CancelException(message, cause, errorLevel)
}

