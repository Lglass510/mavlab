$LabDomain = "glasslab.local"
$LabDC = "DC1"
$LabServer = "SRV2"

$MavLabModulePath = "C:\Projects\mavlab\PowerShell\Modules"

if ($env:PSModulePath -notlike "*$MavLabModulePath*") {
    $env:PSModulePath = "$MavLabModulePath;$env:PSModulePath"
}

