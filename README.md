# MavLab

A personal Windows Server and cloud administration homelab built to practice enterprise infrastructure skills.

## Environment

- Hyper-V virtualization
- Windows Server 2025
- Ubuntu Linux
- Active Directory Domain Services
- DNS
- Group Policy
- PowerShell automation
- Networking
- Azure administration concepts

## Lab Infrastructure

| VM | Role | IPv4 Address | Virtual Switch |
|---|---|---|---|
| DC1 | Domain Controller / DNS | `172.16.10.10` | `mavlab` |
| SRV2 | Windows Server Member Server | `172.16.10.20` | `mavlab` |
| Linux1 | Ubuntu Linux Server | `172.16.10.30` | `mavlab` |

**Network:** `172.16.10.0/24`

## Current Projects

- Active Directory domain deployment
- Windows Server member server deployment
- DNS configuration
- Organizational Unit design
- Group Policy administration
- Linux server configuration
- Network troubleshooting
- PowerShell administration and automation

## Documentation

- [Active Directory Domain Build](ActiveDirectory/domain-build.md)
- [Network Build and Troubleshooting](Networking/network-build.md)
- [Linux Networking](Linux/linux-networking.md)
- [SRV2 Server Core Deployment](ServerCore/srv2-deployment.md)

## Goals

- Prepare for AZ-104 Azure Administrator
- Develop junior system administrator skills
- Build hands-on cloud/server administration experience