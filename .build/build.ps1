# Build environment variables
$buildAgent_ScriptPath = Get-Location
$buildAgent_Environment = "C:\Build"

# Solution tree variables
$solutionName = "BuildSolution"
$solutionFolder = "CHALET_Base"
$projectName = "Configuration"
$plcProjectFile = "Plc_CHALET_Base.plcproj"
$plcName = "Plc_CHALET_Base"
$plcProjectName = "Plc_CHALET_Base Projekt"

# Engineering environment variables
$twincat_4026_64bit_shell = TcXaeShell.DTE.17.0
$twincat_XaeTemplate = "C:\Program Files (x86)\Beckhoff\TwinCAT\3.1\Components\Base\PrjTemplate\TwinCAT Project.tsproj"
$twincat_PlcNode = "TIPC"

# Include message filter class
. "$buildAgent_ScriptPath\tools\MessageFilter.ps1"

# Register COM message filter
AddMessageFilterClass
[EnvDTEUtils.MessageFilter]::Register()

# Open XAE Shell
$shell = new-object -com $twincat_4026_64bit_shell
$shell.SuppressUI = $false
$shell.MainWindow.Visible = $true

# Prepare empty directory
$buildPath = $buildAgent_Environment + "\" + $solutionFolder
if (Test-Path -LiteralPath $buildPath) {
    Remove-Item -LiteralPath $buildPath -Recurse - Force
} else {
    New-Item -ItemType Directory -Force -Path $buildPath
}

# Create new solution
$solution = $shell.solution
$solution.Create($buildAgent_Environment, $solutionFolder)
$solution.SaveAs($buildAgent_Environment + "\" + $solutionFolder + "\" + $solutionName)

# Create new system manger
$project = $solution.AddFromTemplate($xaeProjectTemplate, ($baseFolder + "\" + $solutionFolder + "\" + $projectName), $projectName)
$systemManager = $project.Object

# Add existing plc project (one level above the .build folder)
$plcNode = $systemManager.LookupTreeItem($twincat_PlcNode)
$plcPath = (Split-Path -Path ($buildAgent_ScriptPath).Path -Parent) + "\" 
$plcNode.CreateChild("ExistingPlcProject", 0, "", $plcPath)

# Build the solution
$solution.SolutionBuild.Build($true)

# Save as library
$plcGeneratedNode = $systemManager.LookupTreeItem("$twincat_PlcNode^$plcName^$plcProjectName")
$plcGeneratedNode.SaveAsLibrary("$buildAgent_Environment\$solutionFolder.Library", $false);

# Release resources
$shell.Quit()

[EnvDTEUtils.MessageFilter]::Revoke()
