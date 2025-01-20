# Build environment variables
$buildAgent_ScriptPath = Get-Location
$buildAgent_Environment = "C:\Build"

# Solution tree variables
$solutionName = "BuildSolution"
$solutionFolder = "CHALET_Base"
$projectName = "Configuration"
$plcProjectFile = "Plc_CHALET_Base"
$plcName = "Plc_CHALET_Base"
$plcProjectName = "Plc_CHALET_Base Projekt"

# Engineering environment variables
$twincat_4026_64bit_shell = "TcXaeShell.DTE.17.0"
$twincat_solution_configuration = "Release|TwinCAT RT (x64)"
$twincat_XaeTemplate = "C:\Program Files (x86)\Beckhoff\TwinCAT\3.1\Components\Base\PrjTemplate\TwinCAT Project.tsproj"
$twincat_PlcNode = "TIPC"
$twincat_LicenseNode = "TIRC^License"
$twincat_IoNode = "TIID"

# Import tools
import-module "$buildAgent_ScriptPath\tools\MessageFilter.psm1"
import-module "$buildAgent_ScriptPath\tools\Logger.psm1"
import-module "$buildAgent_ScriptPath\tools\Builder.psm1"

Log "Register COM message filter"
AddMessageFilterClass
[EnvDTEUtils.MessageFilter]::Register()

Log "Open XAE Shell"
$shell = new-object -ComObject $twincat_4026_64bit_shell
$shell.SuppressUI = $false
$shell.MainWindow.Visible = $true
$shellSettings = $shell.GetObject("TcAutomationSettings");
$shellSettings.SilentMode = $true

Log "Prepare empty directory"
$buildPath = "$buildAgent_Environment\$solutionFolder"
if (Test-Path -LiteralPath $buildPath) {
    $null = Remove-Item ($buildPath) -Recurse -Force
} 
$null = New-Item -ItemType Directory -Force -Path $buildPath

Log "Create new solution"
$solution = $shell.solution
$solution.Create($buildAgent_Environment, $solutionFolder)
$solution.SaveAs("$buildAgent_Environment\$solutionFolder\$solutionName")

Log "Create new system manger"
$project = $solution.AddFromTemplate($twincat_XaeTemplate, "$buildAgent_Environment\$solutionFolder\$projectName", $projectName)
$systemManager = $project.Object

Log "Add license dongle with engineering licenses"
$ioNode = $systemManager.LookupTreeItem($twincat_IoNode)
$licenseNode = $systemManager.LookupTreeItem($twincat_LicenseNode)
$usbNode = $ioNode.CreateChild("USB", 57, $null)
$usbNode.ConsumeXml("<TreeItem><DeviceDef><ScanBoxes>1</ScanBoxes></DeviceDef></TreeItem>")
$count = 0;
foreach($usbDevice in $usbNode) {
    if($usbDevice.ItemSubtype -eq 9900){
        if($count -eq 0){
            $licenseNode.CreateChild("Engineering Dongle", 0, $null, $usbDevice.Name)
        } else {
            $licenseNode.CreateChild("Engineering Dongle $count", 0, $null, $usbDevice.Name)
        }     
        $count++
    }
}

Log "Add existing plc project (from one level above the .build folder)"
$plcNode = $systemManager.LookupTreeItem($twincat_PlcNode)
$plcPath = (Split-Path -Path ($buildAgent_ScriptPath).Path -Parent) + "\" 
$null = $plcNode.CreateChild("ExistingPlcProject", 0, "", "$plcPath\$plcProjectFile.plcproj")
$plcGeneratedNode = $systemManager.LookupTreeItem("$twincat_PlcNode^$plcName^$plcProjectName")

Log "Get plc project version"
$plcXml =  [xml]$plcGeneratedNode.ProduceXml();
$plcVersion = $plcXml.TreeItem.IECProjectDef.ProjectInfo.Version;
$plcVersion = $plcVersion -replace '\.', '_'
$plcTitle = $plcXml.TreeItem.IECProjectDef.ProjectInfo.Title;

Log "Build the solution"
BuildWithConfiguration $solution "$buildAgent_Environment\$solutionFolder\$projectName\$projectName.tsproj" $twincat_solution_configuration

Log "Save as library"
mkdir bin;
$null = $plcGeneratedNode.SaveAsLibrary("$buildAgent_ScriptPath\bin\$plcTitle"+"_"+"$plcVersion.Library", $false);

Log "Release the shell"
$null = $shell.Quit();
[EnvDTEUtils.MessageFilter]::Revoke()

Log "The library $plcTitle with version $plcVersion was built successfully!"