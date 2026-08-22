$LabDomain = "mavlab.local"
$LabDC = "Glass-DC1"
$LabServer = "Glass-SVR1"

$MavLabModulePath = "C:\Projects\mavlab\PowerShell\Modules"

if ($env:PSModulePath -notlike "*$MavLabModulePath*") {
    $env:PSModulePath = "$MavLabModulePath;$env:PSModulePath"
}

