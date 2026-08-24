
# Active Directory Employee Onboarding Automation

## Overview

This lab demonstrates a PowerShell-based Active Directory onboarding workflow for creating and configuring employee accounts from CSV data.

The workflow was designed to simulate a small organizational environment with:

- Department-based Organizational Units (OUs)
- Manager accounts and reporting relationships
- Employee accounts
- Contractor and remote-worker security groups
- Automated user creation and placement
- Automated manager assignment
- Automated security group membership

The goal was to practice administering Active Directory through PowerShell while building automation around a realistic employee onboarding process.

---

## Lab Structure

### Employee OUs

Employee accounts are organized under the `Employees` OU by department:

```text
Employees
├── HR
├── IT
├── Legal
├── Finance
└── Sales
````

### Manager OUs

Manager accounts are organized separately under the `Managers` OU:

```text
Managers
├── HR
├── IT
├── Legal
├── Finance
└── Sales
```

Each departmental manager OU contains the managers responsible for that department.

### Security Groups

Two security groups were created to support additional access and policy management:

```text
Contractors
RemoteWorkers
```

These groups are populated based on employee attributes in the onboarding CSV.

---

# Employee Data

Employee information is maintained in a CSV file:

```text
C:\Users\Administrator\Documents\Data\mavlab_employees.csv
```

The employee CSV contains:

```text
FirstName
LastName
Department
Title
Username
Manager
Contractor
Remote
```

Example:

```text
FirstName  : Charlotte
LastName   : Bronte
Department : IT
Title      : Systems Administrator
Username   : cbronte
Manager    : it.manager
Contractor : FALSE
Remote     : FALSE
```

The CSV acts as the source of truth for the employee onboarding process.

---

# Manager Data

Manager information is maintained separately in:

```text
C:\Users\Administrator\Documents\Data\mavlab_managers.csv
```

The manager CSV contains:

```text
Name
Username
Department
Title
```

Example:

```text
Name       : Mary Robinette Kowal
Username   : mkowal
Department : IT
Title      : it manager
```

Manager accounts were created and placed into their corresponding departmental manager OU.

---

# Manager Mapping

The employee CSV uses values such as:

```text
it.manager
hr.manager
finance.manager
legal.manager
sales.manager
```

These values are not the managers' actual usernames.

A PowerShell hashtable was created to translate those labels into the actual AD usernames:

```powershell
$ManagerMap = @{
    "it.manager"      = "mkowal"
    "hr.manager"      = "rsolomon"
    "legal.manager"   = "khosseini"
    "finance.manager" = "sjmaas"
    "sales.manager"   = "matwood"
}
```

This allows the employee CSV to remain unchanged while still establishing actual Active Directory manager relationships.

---

# Employee OU Placement

The employee's `Department` value is used to determine the destination OU.

For example:

```text
Department = IT
```

becomes:

```text
OU=IT,OU=Employees,DC=glasslab,DC=local
```

The PowerShell variable used to construct the destination was:

```powershell
$OU = "OU=$($Employee.Department),OU=Employees,DC=glasslab,DC=local"
```

This allowed the same script to place employees into the correct departmental OU automatically.

---

# User Creation

Employee accounts were created using `New-ADUser`.

The following CSV properties were mapped to Active Directory attributes:

| CSV Field  | AD Attribute         |
| ---------- | -------------------- |
| FirstName  | GivenName            |
| LastName   | Surname              |
| Username   | SamAccountName       |
| Username   | UserPrincipalName    |
| Department | Department           |
| Title      | Title                |
| Department | OU placement         |
| Manager    | Manager relationship |
| Contractor | Contractors group    |
| Remote     | RemoteWorkers group  |

The initial lab password was applied to newly created accounts and users were configured to change their password at first logon.

---

# Existing User Check

Before creating an account, the script checks whether the username already exists:

```powershell
$ExistingUser = Get-ADUser -Filter "SamAccountName -eq '$($Employee.Username)'"
```

If the account already exists, the script skips it:

```powershell
if ($ExistingUser) {
    Write-Host "$($Employee.Username) already exists - skipping"
    continue
}
```

This prevents the script from attempting to recreate existing accounts.

---

# Manager Assignment

The manager relationship was established in multiple steps.

First, the employee's CSV value was used to query the manager mapping:

```powershell
$ManagerUsername = $ManagerMap[$Employee.Manager]
```

The manager account was then retrieved from Active Directory:

```powershell
$Manager = Get-ADUser -Identity $ManagerUsername
```

The manager's Distinguished Name (DN) was then assigned to the employee:

```powershell
Set-ADUser `
    -Identity $Employee.Username `
    -Manager $Manager.DistinguishedName
```

For example:

```text
Charlotte Bronte
        |
        | Manager
        v
Mary Robinette Kowal
```

Charlotte's AD Manager attribute ultimately contains:

```text
CN=Mary Robinette Kowal,OU=IT,OU=Managers,DC=glasslab,DC=local
```

This demonstrated that the AD `Manager` attribute uses the manager's Distinguished Name rather than simply storing a username.

---

# Contractor and Remote Worker Groups

The employee CSV contains two boolean-style fields:

```text
Contractor
Remote
```

These values determine group membership.

### Contractors

If:

```text
Contractor = TRUE
```

the user is added to:

```text
Contractors
```

using:

```powershell
Add-ADGroupMember `
    -Identity "Contractors" `
    -Members $Employee.Username
```

### Remote Workers

If:

```text
Remote = TRUE
```

the user is added to:

```text
RemoteWorkers
```

using:

```powershell
Add-ADGroupMember `
    -Identity "RemoteWorkers" `
    -Members $Employee.Username
```

The conditions are evaluated independently so a user can belong to both groups.

For example:

```text
Rivers Solomon
Contractor = TRUE
Remote     = TRUE
```

results in membership in:

```text
Contractors
RemoteWorkers
```

---

# Validation and Testing

The automation was developed incrementally rather than immediately running against the entire employee dataset.

The workflow was tested in stages:

1. Imported the employee CSV.
2. Verified CSV properties using `Get-Member`.
3. Confirmed employee OU paths.
4. Created and verified manager accounts.
5. Created the `ManagerMap`.
6. Tested manager lookup using an employee record.
7. Assigned a manager to a test employee.
8. Verified the AD `Manager` attribute.
9. Created Contractor and RemoteWorkers groups.
10. Tested group membership using an employee marked as both contractor and remote.
11. Generated a preview of all employee records before account creation.
12. Ran the final onboarding automation against the employee dataset.
13. Verified employees were created and placed into their appropriate departmental OUs.

---

# Final Employee Onboarding Workflow

The completed automation follows this process:

```text
Employee CSV
     |
     v
Check existing account
     |
     +---- Already exists ---> Skip
     |
     v
Determine Department OU
     |
     v
Resolve Manager value
     |
     v
Look up Manager in AD
     |
     v
Create Employee Account
     |
     v
Assign Manager
     |
     +---- Contractor = TRUE ---> Contractors
     |
     +---- Remote = TRUE -------> RemoteWorkers
```

This workflow was used to create the employee accounts and configure their organizational placement, manager relationships, and applicable security group memberships.

---

# PowerShell Concepts Practiced

This lab provided hands-on practice with:

* `Import-Csv`
* `ForEach`
* `Where-Object`
* Hashtables
* Variables
* String interpolation
* `Get-ADUser`
* `New-ADUser`
* `Set-ADUser`
* `Add-ADGroupMember`
* Distinguished Names (DNs)
* OU paths
* Active Directory user attributes
* Security group membership
* Conditional logic
* Error handling
* Existing-object detection
* CSV-driven automation

---

# Future Lab Expansion

Potential next steps include:

* Applying GPOs to contractor and remote-worker groups
* Creating additional departmental security groups
* Expanding manager relationships
* Adding account expiration for contractors
* Creating disabled-user/offboarding automation
* Adding logging to the onboarding script
* Adding error reporting
* Building a reusable PowerShell function/module for employee onboarding
* Testing bulk onboarding with different CSV datasets
* Automating onboarding and offboarding workflows

````


