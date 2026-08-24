Active Directory Script



&#x20;$Employees = Import-Csv "C:\\Users\\Administrator\\Documents\\Data\\mavlab\_employees. csv"

&#x20;foreach ($Employee in $Employees) {

&#x20;$Department = $Employee. Department

&#x20;$OU = "OU=$Department, OU=Employees, DC=glasslab, DC=local"

&#x20;Write-Host "$($Employee.FirstName) $($Employee.LastName) -> $OU"







$Employees = Import-Csv "C:\\Users\\Administrator\\Documents\\Data\\mavlab\_employees.csv"



$Employee = $Employees\[0]



$OU = "OU=$($Employee.Department),OU=Employees,DC=glasslab,DC=local"



$Password = ConvertTo-SecureString "MavLab123!" -AsPlainText -Force



New-ADUser `

&#x20;   -Name "$($Employee.FirstName) $($Employee.LastName)" `

&#x20;   -GivenName $Employee.FirstName `

&#x20;   -Surname $Employee.LastName `

&#x20;   -SamAccountName $Employee.Username `

&#x20;   -UserPrincipalName "$($Employee.Username)@glasslab.local" `

&#x20;   -Title $Employee.Title `

&#x20;   -Department $Employee.Department `

&#x20;   -Path $OU `

&#x20;   -AccountPassword $Password `

&#x20;   -Enabled $true `

&#x20;   -ChangePasswordAtLogon $true



**Employee Creation/Sorting Script**

foreach ($Employee in $Employees) {



&#x20;   # Build employee OU

&#x20;   $OU = "OU=$($Employee.Department),OU=Employees,DC=glasslab,DC=local"



&#x20;   # Check if employee already exists

&#x20;   $ExistingUser = Get-ADUser -Filter "SamAccountName -eq '$($Employee.Username)'"



&#x20;   if ($ExistingUser) {

&#x20;       Write-Host "$($Employee.Username) already exists - skipping"

&#x20;       continue

&#x20;   }



&#x20;   # Resolve manager

&#x20;   $ManagerUsername = $ManagerMap\[$Employee.Manager]



&#x20;   if (-not $ManagerUsername) {

&#x20;       Write-Warning "$($Employee.Username): No manager mapping found for '$($Employee.Manager)' - skipping"

&#x20;       continue

&#x20;   }



&#x20;   $Manager = Get-ADUser -Identity $ManagerUsername -ErrorAction SilentlyContinue



&#x20;   if (-not $Manager) {

&#x20;       Write-Warning "$($Employee.Username): Manager '$ManagerUsername' not found in AD - skipping"

&#x20;       continue

&#x20;   }



&#x20;   # Create employee

&#x20;   New-ADUser `

&#x20;       -Name "$($Employee.FirstName) $($Employee.LastName)" `

&#x20;       -GivenName $Employee.FirstName `

&#x20;       -Surname $Employee.LastName `

&#x20;       -SamAccountName $Employee.Username `

&#x20;       -UserPrincipalName "$($Employee.Username)@glasslab.local" `

&#x20;       -Title $Employee.Title `

&#x20;       -Department $Employee.Department `

&#x20;       -Path $OU `

&#x20;       -AccountPassword $Password `

&#x20;       -Enabled $true `

&#x20;       -ChangePasswordAtLogon $true



&#x20;   Write-Host "Created: $($Employee.FirstName) $($Employee.LastName)"



&#x20;   # Assign manager

&#x20;   Set-ADUser `

&#x20;       -Identity $Employee.Username `

&#x20;       -Manager $Manager.DistinguishedName



&#x20;   Write-Host "  Manager: $($Manager.Name)"



&#x20;   # Contractor group

&#x20;   if ($Employee.Contractor -eq "TRUE") {

&#x20;       Add-ADGroupMember `

&#x20;           -Identity "Contractor" `

&#x20;           -Members $Employee.Username



&#x20;       Write-Host "  Added to Contractor Group"

&#x20;   }



&#x20;   # Remote group

&#x20;   if ($Employee.Remote -eq "TRUE") {

&#x20;       Add-ADGroupMember `

&#x20;           -Identity "Remote" `

&#x20;           -Members $Employee.Username



&#x20;       Write-Host "  Added to Remote Group"

&#x20;   }

}

