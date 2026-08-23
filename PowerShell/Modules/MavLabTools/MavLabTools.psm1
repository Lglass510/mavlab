function Get-LabUsers {
    Get-ADUser -Filter * | Select-Object Name, SamAccountName, Enabled
}

Export-ModuleMember -Function Get-LabUsers


function New-LabDepartment {

     param (
        [Parameter(Mandatory)]
        [string]$Department,

        [Parameter(Mandatory)]
        [ValidateSet("Employees", "Managers")]
        [string]$ParentOU
    )

    $ParentOUPath = "OU=$ParentOU,DC=glasslab,DC=local"
    $DepartmentOU = "OU=$Department,$ParentOU"

    try {
        Get-ADOrganizationalUnit -Identity $DepartmentOU -ErrorAction Stop

        Write-Host "Department '$Department' already exists under '$ParentOU'."
    }
    catch {
        New-ADOrganizationalUnit `
            -Name $Department `
            -Path $ParentOU

        Write-Host "Department '$Department' created successfully under '$ParentOU'."
    }
}

Export-ModuleMember -Function New-LabDepartment
