# Define and assign directory and naming variables
$workingDirectory = Get-Location

$baseFolder = "C:\BuildFolder"
$solutionFolder = "CHALET_Base"
$solutionName = "BuildSolution"
$projectName = "Configuration"

$xaeProjectTemplate = "C:\Program Files (x86)\Beckhoff\TwinCAT\3.1\Components\Base\PrjTemplate\TwinCAT Project.tsproj"
$plcProjectSource = "Plc_CHALET_Base.plcproj"

# Include further scripts
. "$WorkingDirectory\tools\MessageFilter.ps1"

# Register COM message filter
AddMessageFilterClass
[EnvDTEUtils.MessageFilter]::Register()

# Open XAE Shell
$shell = new-object -com TcXaeShell.DTE.17.0
$shell.SuppressUI = $false
$shell.MainWindow.Visible = $true

# Prepare directory
Remove-Item ($baseFolder + "\" + $solutionFolder) -Recurse -Force
New-Item -ItemType Directory -Force -Path ($baseFolder + "\" + $solutionFolder)

# Create new solution
$solution = $shell.solution
$solution.Create($baseFolder, $solutionFolder)
$solution.SaveAs($baseFolder + "\" + $solutionFolder + "\" + $solutionName)

# Create new system manger
$project = $solution.AddFromTemplate($xaeProjectTemplate, ($baseFolder + "\" + $solutionFolder + "\" + $projectName), $projectName)
$systemManager = $project.Object

# Add existing plc project
$plcNode = $systemManager.LookupTreeItem("TIPC")
$plcPath = (Split-Path -Path ($workingDirectory).Path -Parent) + "\" + $plcProjectSource
$plcNode.CreateChild("ExistingPlcProject", 0, "", $plcPath)

# Build the solution
$solution.SolutionBuild.Build($true)

# Save as library
$plcGeneratedNode = $systemManager.LookupTreeItem("TIPC^Plc_CHALET_Base^Plc_CHALET_Base Projekt")
$plcGeneratedNode.SaveAsLibrary("C:\BuildFolder\CHALET_Base.Library", $false);

# Release resources
$shell.Quit()

[EnvDTEUtils.MessageFilter]::Revoke()
