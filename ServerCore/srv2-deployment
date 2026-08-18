# SRV2 Server Core Deployment

## Overview

SRV2 is a Windows Server 2025 Standard Evaluation virtual machine deployed as a domain member server within the MavLab environment.

The server was deployed using the **Server Core** installation option and joined to the existing `glasslab.local` Active Directory domain.

## Server Configuration

| Configuration     | Value                                   |
| ----------------- | --------------------------------------- |
| Hostname          | `SRV2`                                  |
| Operating System  | Windows Server 2025 Standard Evaluation |
| Installation Type | Server Core                             |
| Role              | Domain Member Server                    |
| Domain            | `glasslab.local`                        |
| Domain Controller | `DC1`                                   |
| DNS Server        | `172.31.250.10`                         |

### Initial Network Configuration

SRV2 was initially connected to the Hyper-V **Default Switch**.

| Configuration   | Value            |
| --------------- | ---------------- |
| IPv4 Address    | `172.31.242.194` |
| Subnet Mask     | `255.255.240.0`  |
| Default Gateway | `172.31.240.1`   |
| DNS Server      | `172.31.250.10`  |

## Domain Integration

SRV2 was successfully joined to the existing `glasslab.local` Active Directory domain.

DC1 remained responsible for Active Directory Domain Services and DNS.

```text
DC1
172.31.250.10
glasslab.local
```

Domain integration was verified by confirming that:

* SRV2 could discover the domain controller.
* SRV2 successfully joined the `glasslab.local` domain.
* The SRV2 computer account was created in Active Directory.
* SRV2 could communicate with the domain controller's DNS service.

## Troubleshooting

### Initial Connectivity Issue

During deployment, SRV2 was unable to successfully ping DC1 even though both systems were connected to the Hyper-V Default Switch and configured within the same `/20` network.

Rather than assuming that failed ICMP communication represented a complete network failure, additional connectivity testing was performed.

### DNS Connectivity Test

PowerShell was used to test TCP connectivity to the DNS service on DC1:

```powershell
Test-NetConnection 172.31.250.10 -Port 53
```

The test returned:

```text
TcpTestSucceeded : True
```

This demonstrated that SRV2 was able to establish a TCP connection to DC1's DNS service.

The failed ICMP test therefore did not indicate that all communication between SRV2 and DC1 was unavailable.

### DNS Resolution

DNS resolution was also tested for:

```text
glasslab.local
```

Successful DNS communication supported the conclusion that SRV2 had functional network access to the domain controller even though ICMP testing was unsuccessful.

## Domain Controller Discovery

Domain controller discovery was tested using:

```cmd
nltest /dsgetdc:glasslab.local
```

This was used to verify that SRV2 could locate a domain controller for the `glasslab.local` domain.

## Lessons Learned

The troubleshooting process demonstrated that a failed `ping` test does not necessarily mean that two systems cannot communicate.

Different network tests validate different things:

| Test                          | What It Validates           |
| ----------------------------- | --------------------------- |
| `ping`                        | ICMP connectivity           |
| `Test-NetConnection -Port 53` | TCP connectivity to DNS     |
| DNS lookup                    | Name resolution             |
| `nltest /dsgetdc`             | Domain controller discovery |

Testing a specific service or port can provide more useful information than relying exclusively on ICMP.

## Skills Practiced

* Windows Server 2025 Server Core deployment
* Hyper-V virtual machine configuration
* Server Core administration
* IPv4 configuration
* DNS configuration
* Active Directory domain joining
* Domain controller discovery
* DNS troubleshooting
* Network troubleshooting
* TCP port testing with PowerShell
* `Test-NetConnection`
* `nltest`
* Active Directory computer management

## Next Steps

Future work for SRV2 includes:

* Configure and verify additional Windows Server roles
* Practice remote administration of Server Core
* Test PowerShell remoting
* Verify SMB connectivity
* Practice Windows Server administration without a graphical interface
* Integrate SRV2 further into the MavLab infrastructure
