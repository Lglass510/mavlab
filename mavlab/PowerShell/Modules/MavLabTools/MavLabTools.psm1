function Get-LabUsers {
    Get-ADUser -Filter * | Select-Object Name, SamAccountName, Enabled
}

Export-ModuleMember -Function Get-LabUsers


function New-LabDepartment {

    param (
        [Parameter(Mandatory)]
        [string]$Department
    )

    $EmployeesOU = "OU=Employees,DC=glasslab,DC=local"
    $DepartmentOU = "OU=$Department,$EmployeesOU"

    try {
        Get-ADOrganizationalUnit -Identity $DepartmentOU -ErrorAction Stop

        Write-Host "Department '$Department' already exists."
    }
    catch {
        New-ADOrganizationalUnit `
            -Name $Department `
            -Path $EmployeesOU

        Write-Host "Department '$Department' created successfully."
    }
}

Export-ModuleMember -Function New-LabDepartment
