# 🖥️ Active Directory Employee Onboarding Automation

> A PowerShell-powered lab simulating end-to-end employee onboarding in Active Directory — from CSV to fully provisioned account.

![Status](https://img.shields.io/badge/status-complete-brightgreen) ![Tech](https://img.shields.io/badge/tooling-PowerShell-blue) ![Env](https://img.shields.io/badge/environment-Active%20Directory-orange)

---

## 📖 The Story

Every real IT department deals with onboarding: new hires show up in a spreadsheet, and someone (or something) has to turn that spreadsheet into working accounts — placed in the right OU, tied to the right manager, and dropped into the right security groups.

This lab recreates that process from scratch inside a simulated organization, **GlassLab**, using nothing but PowerShell and two CSV files as the source of truth. The goal wasn't just to run a script — it was to build the automation piece by piece, test each piece in isolation, and only then let it loose on the full dataset.

---

## 🏗️ Lab Structure

The AD environment was organized into a clean departmental hierarchy, with employees and managers kept in **separate OU trees**:

```text
Employees                          Managers
├── HR                             ├── HR
├── IT                             ├── IT
├── Legal                          ├── Legal
├── Finance                        ├── Finance
└── Sales                          └── Sales
```

Two security groups round out the access model:

```text
Contractor
Remote
```

---

## 🧾 Step 1 — The Source Data

Two CSVs drive the entire workflow:

**`mavlab_employees.csv`** — the new hires
```text
FirstName, LastName, Department, Title, Username, Manager, Contractor, Remote
```

**`mavlab_managers.csv`** — the leadership layer, created first so employees would have someone to report to
```text
Name, Username, Department, Title
```

---

## 👔 Step 2 — Standing Up the Managers

Before any employee could be onboarded, managers needed to exist in AD. Using `Where-Object`, the manager list was filtered down to a single department to verify the logic before running it against everyone:

![Filtering and creating manager accounts](images/manager_creation.png)

Each manager was created with `New-ADUser` and placed into their departmental OU under `Managers`, using the same `$OU` string-building pattern that would later be reused for employees.

---

## 🗺️ Step 3 — Solving the Manager Mapping Problem

The employee CSV didn't reference managers by their real usernames — it used generic role labels like `it.manager` or `hr.manager`. Rather than editing the source data, a hashtable was built to translate those labels into real AD identities:

![Importing employees and building the ManagerMap](images/managermap_setup.png)

```powershell
$ManagerMap = @{
    "it.manager"      = "mkowal"
    "hr.manager"      = "rsolomon"
    "legal.manager"   = "khosseini"
    "finance.manager" = "sjmaas"
    "sales.manager"   = "matwood"
}
```

This kept the CSV format decoupled from the actual AD environment — a small design choice that made the whole system more resilient.

---

## ⚙️ Step 4 — The Full Onboarding Engine

With managers created and the mapping in place, the full `foreach` loop brought everything together: OU placement, duplicate detection, manager resolution, account creation, and conditional group assignment.

![The complete employee onboarding loop](images/employee_onboarding_script.png)

```powershell
foreach ($Employee in $Employees) {

    # Build employee OU
    $OU = "OU=$($Employee.Department),OU=Employees,DC=glasslab,DC=local"

    # Check if employee already exists
    $ExistingUser = Get-ADUser -Filter "SamAccountName -eq '$($Employee.Username)'"

    if ($ExistingUser) {
        Write-Host "$($Employee.Username) already exists - skipping"
        continue
    }

    # Resolve manager
    $ManagerUsername = $ManagerMap[$Employee.Manager]

    if (-not $ManagerUsername) {
        Write-Warning "$($Employee.Username): No manager mapping found for '$($Employee.Manager)' - skipping"
        continue
    }

    $Manager = Get-ADUser -Identity $ManagerUsername -ErrorAction SilentlyContinue

    if (-not $Manager) {
        Write-Warning "$($Employee.Username): Manager '$ManagerUsername' not found in AD - skipping"
        continue
    }

    # Create employee
    New-ADUser `
        -Name "$($Employee.FirstName) $($Employee.LastName)" `
        -GivenName $Employee.FirstName `
        -Surname $Employee.LastName `
        -SamAccountName $Employee.Username `
        -UserPrincipalName "$($Employee.Username)@glasslab.local" `
        -Title $Employee.Title `
        -Department $Employee.Department `
        -Path $OU `
        -AccountPassword $Password `
        -Enabled $true `
        -ChangePasswordAtLogon $true

    Write-Host "Created: $($Employee.FirstName) $($Employee.LastName)"

    # Assign manager
    Set-ADUser `
        -Identity $Employee.Username `
        -Manager $Manager.DistinguishedName

    Write-Host "  Manager: $($Manager.Name)"

    # Contractor group
    if ($Employee.Contractor -eq "TRUE") {
        Add-ADGroupMember `
            -Identity "Contractor" `
            -Members $Employee.Username

        Write-Host "  Added to Contractor Group"
    }

    # Remote group
    if ($Employee.Remote -eq "TRUE") {
        Add-ADGroupMember `
            -Identity "Remote" `
            -Members $Employee.Username

        Write-Host "  Added to Remote Group"
    }
}
```

### What this loop does, in order:

1. **Builds the destination OU** from the employee's `Department` field
2. **Checks for an existing account** via `Get-ADUser -Filter` and skips duplicates
3. **Resolves the manager label** through `$ManagerMap`, warning and skipping if no mapping exists
4. **Looks up the manager in AD**, warning and skipping if the manager account isn't found
5. **Creates the employee account** with `New-ADUser`, forcing a password change at first logon
6. **Assigns the manager relationship** by writing the manager's Distinguished Name to the employee's `Manager` attribute
7. **Evaluates group membership** independently for `Contractor` and `Remote`, so a user can land in both, one, or neither group

---

## 🔗 Why the Manager Relationship Actually Works

The interesting AD detail here: the `Manager` attribute doesn't store a username — it stores a **Distinguished Name**.

```text
Charlotte Bronte
        │
        │  Manager
        ▼
Mary Robinette Kowal
```

So after the script runs, Charlotte's `Manager` attribute literally contains:

```text
CN=Mary Robinette Kowal,OU=IT,OU=Managers,DC=glasslab,DC=local
```

That's why the script has to fully resolve the manager object with `Get-ADUser` before it can assign anything — `Set-ADUser -Manager` needs that DN, not just a name.

---

## 🏷️ Contractor & Remote Worker Groups

Two independent boolean checks drive group membership:

| CSV Field | If `TRUE` → Added to |
|---|---|
| `Contractor` | `Contractor` |
| `Remote` | `Remote` |

Because the checks are independent, an employee like **Rivers Solomon** — marked `Contractor = TRUE` and `Remote = TRUE` — ends up in *both* groups.

---

## ✅ How It Was Validated

Rather than pointing the script at the full dataset on the first try, the build-out was incremental:

1. Import the employee CSV
2. Inspect properties with `Get-Member`
3. Confirm OU path construction
4. Create and verify manager accounts
5. Build the `ManagerMap`
6. Test manager lookup on a single record
7. Assign a manager to one test employee
8. Verify the `Manager` attribute in AD
9. Create the `Contractor` / `Remote` groups
10. Test group membership on a dual contractor+remote employee
11. Preview *all* records before touching AD
12. Run the full onboarding automation
13. Verify final OU placement for every employee

This step-by-step approach caught mapping and OU issues early, before they could cascade across the whole dataset.

---

## 🔄 End-to-End Workflow

```text
Employee CSV
     │
     ▼
Check existing account ──── Already exists? ──▶ Skip
     │
     ▼
Determine Department OU
     │
     ▼
Resolve Manager label ──▶ ManagerMap
     │
     ▼
Look up Manager in AD
     │
     ▼
Create Employee Account
     │
     ▼
Assign Manager (DN)
     │
     ├── Contractor = TRUE ──▶ Contractor group
     │
     └── Remote = TRUE ──────▶ Remote group
```

---

## 🧠 Concepts Practiced

`Import-Csv` · `ForEach` · `Where-Object` · Hashtables · String interpolation · `Get-ADUser` · `New-ADUser` · `Set-ADUser` · `Add-ADGroupMember` · Distinguished Names · OU path construction · Conditional logic · Error handling · Existing-object detection · CSV-driven automation

---

## 🚀 What's Next

- [ ] Apply GPOs to `Contractor` and `Remote` groups
- [ ] Add more granular departmental security groups
- [ ] Expand and test additional manager relationships
- [ ] Add account expiration dates for contractors
- [ ] Build a disabled-user / offboarding automation counterpart
- [ ] Add structured logging to the onboarding script
- [ ] Add proper error reporting/alerting
- [ ] Refactor into a reusable PowerShell function or module
- [ ] Test bulk onboarding against different CSV datasets
- [ ] Chain onboarding + offboarding into a single lifecycle workflow

---

*Lab environment: `glasslab.local` — simulated corporate domain for AD administration practice.*
