function BuildWithConfiguration {
	param (
		$solution,
		$project,
		$configuration
	)

	log  "Build the project with configuration $configuration"
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