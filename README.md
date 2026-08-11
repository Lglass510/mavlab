# MavLab

A personal Windows Server and cloud administration homelab built to practice enterprise infrastructure skills.

## Environment

- Hyper-V virtualization
- Windows Server 2025
- Active Directory Domain Services
- DNS
- Group Policy
- PowerShell automation
- Azure administration concepts

## Current Projects

- Building an Active Directory domain
- Configuring users, groups, and organizational units
- Implementing Group Policy Objects
- Practicing PowerShell administration
- Documenting server administration tasks

## Latest Lab Update — Windows Server Core Member Server

### SRV2 Deployment

Added a second Windows Server to the MavLab environment using **Windows Server 2025 Standard Evaluation — Server Core**.

**SRV2 Configuration**

* OS: Windows Server 2025 Server Core
* Hostname: `SRV2`
* Domain: `glasslab.local`
* Role: Domain Member Server
* Hyper-V Virtual Switch: Default Switch
* IPv4 Address: `172.31.242.194`
* Subnet Mask: `255.255.240.0`
* Default Gateway: `172.31.240.1`
* DNS Server: `172.31.250.10` (DC1)

### Domain Integration

SRV2 was successfully joined to the existing `glasslab.local` Active Directory domain.

DC1 remains the domain controller and DNS server:

* DC1: `172.31.250.10`
* Domain: `glasslab.local`

Verified that SRV2 could discover the domain controller and confirmed that the computer was successfully added to Active Directory.

### Troubleshooting Performed

During deployment, SRV2 was unable to successfully ping DC1 even though both servers were connected to the same Hyper-V Default Switch and were configured within the same `/20` subnet.

Additional testing showed that DNS communication was successful:

```powershell id="r6u9tz"
Test-NetConnection 172.31.250.10 -Port 53
```

Result:

```text
TcpTestSucceeded : True
```

This demonstrated that the failed ICMP ping did not indicate a complete network failure. SRV2 was able to communicate with DC1's DNS service.

DNS resolution was also verified for:

```text
glasslab.local
```

### Skills Practiced

* Windows Server 2025 Server Core deployment
* Hyper-V virtual machine configuration
* IPv4 configuration
* DNS configuration
* Active Directory domain joining
* Server Core administration
* Network troubleshooting
* DNS troubleshooting
* TCP port testing with PowerShell
* Domain controller discovery with `nltest`
* Active Directory computer management


## Goals

- Prepare for AZ-104 Azure Administrator
- Develop junior system administrator skills
- Build hands-on cloud/server administration experience