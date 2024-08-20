function BuildWithConfiguration {
	param (
		$solution,
		$project,
		$configuration
	)

	log  "Build configuratoin '$configuration' of project: $project"
	$solution.solutionBuild.BuildProject("$configuration", $project, $true)

	$lastBuildInfo = $solution.solutionBuild.LastBuildInfo

	if($lastBuildInfo -eq 0){
		log "Build succeeded"
	}
	else{
		log "Build failed"
		$dte.Quit()
		Exit 1
	}

}