# MavLab — Hyper-V NAT & Virtual Network

## Overview

This lab establishes a private virtual network in Hyper-V using a custom virtual switch and Windows NAT.

The goal is to create an isolated `172.16.10.0/24` lab network where Windows Server and Linux virtual machines can communicate with each other and reach the Internet through the Windows 11 Hyper-V host.

The lab also serves as a foundation for future Active Directory, DNS, PowerShell automation, and Windows/Linux administration projects.

---

## Network Topology

```text
                              INTERNET
                                  |
                                  |
                         Windows 11 Host
                         172.16.10.1
                                  |
                           Windows NAT
                            MavLabNAT
                                  |
                           mavlab Switch
                         172.16.10.0/24
                                  |
             +--------------------+--------------------+
             |                    |                    |
             |                    |                    |
        Glass-DC1            Glass-SVR1             Linux1
        172.16.10.10         172.16.10.20         172.16.10.30
        AD / DNS                                      Ubuntu
```

---

## Addressing Plan

| Device | IPv4 Address | Subnet Mask | Default Gateway | DNS Server | Role |
|---|---|---|---|---|---|
| Windows 11 Host | `172.16.10.1` | `255.255.255.0` | — | Host DNS | Hyper-V Host / NAT Gateway |
| Glass-DC1 | `172.16.10.10` | `255.255.255.0` | `172.16.10.1` *(pending)* | `172.16.10.10` | Domain Controller / DNS |
| Glass-SVR1 | `172.16.10.20` | `255.255.255.0` | `172.16.10.1` *(pending)* | `172.16.10.10` | Windows Server |
| Linux1 | `172.16.10.30` | `255.255.255.0` | `172.16.10.1` | `172.16.10.10` | Ubuntu Linux Server |

### Network Details

| Setting | Value |
|---|---|
| Network | `172.16.10.0/24` |
| Subnet Mask | `255.255.255.0` |
| Gateway | `172.16.10.1` |
| Internal DNS | `172.16.10.10` |
| Hyper-V Switch | `mavlab` |
| Windows NAT | `MavLabNAT` |
| NAT Internal Prefix | `172.16.10.0/24` |

---

## 1. Hyper-V Virtual Switch

Created a custom Hyper-V virtual switch named:

```text
mavlab
```

The virtual machines are connected to this switch.

The switch provides Layer 2 connectivity between the lab machines.

### Connected Systems

- Glass-DC1
- Glass-SVR1
- Linux1

All systems are intended to communicate through:

```text
mavlab
172.16.10.0/24
```

---

## 2. Windows NAT Configuration

Windows NAT was configured on the Hyper-V host using PowerShell 7.

```powershell
New-NetNat `
    -Name "MavLabNAT" `
    -InternalIPInterfaceAddressPrefix "172.16.10.0/24"
```

### NAT Configuration

```text
Name:              MavLabNAT
Internal Network:  172.16.10.0/24
Active:             True
```

### Verification

```powershell
Get-NetNat
```

This confirmed that the NAT object was active.

---

## 3. PowerShell Version Troubleshooting

Initially, `New-NetNat` was attempted from Windows PowerShell 5.1.

The command was not recognized:

```text
New-NetNat : The term 'New-NetNat' is not recognized...
```

PowerShell 7 was opened and the command was verified:

```powershell
Get-Command New-NetNat
```

The command was available through the `NetNat` module.

### Lesson

When a PowerShell command is not recognized:

1. Verify the PowerShell version.
2. Check whether the command exists.
3. Check the associated module.
4. Verify administrative privileges if required.

Useful commands:

```powershell
$PSVersionTable.PSVersion
Get-Command New-NetNat
```

---

## 4. Linux Static Network Configuration

Linux1 was configured with a static IPv4 address:

```text
IP Address: 172.16.10.30
Subnet:     /24
DNS:        172.16.10.10
```

The Netplan configuration is stored in:

```text
/etc/netplan/50-cloud-init.yaml
```

The configuration was updated to include a default route:

```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses:
        - 172.16.10.30/24
      routes:
        - to: default
          via: 172.16.10.1
      nameservers:
        addresses:
          - 172.16.10.10
```

### Important Netplan Concepts

Netplan uses YAML configuration.

YAML indentation is significant.

Spaces are used for indentation rather than tabs.

The following defines the default route:

```yaml
routes:
  - to: default
    via: 172.16.10.1
```

The default route tells Linux where to send traffic destined for networks outside its local subnet.

---

## 5. Netplan Troubleshooting

An initial attempt to configure the gateway produced YAML syntax errors.

Examples:

```text
Invalid YAML: did not find expected
```

and:

```text
Invalid YAML: inconsistent indentation
```

The configuration was rewritten using proper YAML indentation.

The configuration was tested with:

```bash
sudo netplan try
```

Netplan accepted the configuration.

### Verification

```bash
ip route
```

Result:

```text
default via 172.16.10.1 dev eth0 proto static
172.16.10.0/24 dev eth0 proto kernel scope link src 172.16.10.30
```

This confirmed that Linux now has a default gateway.

---

## 6. Connectivity Testing

Connectivity was tested progressively instead of assuming the network was working.

### Test 1 — Local Gateway

```bash
ping -c 4 172.16.10.1
```

Result:

```text
Successful
0% packet loss
```

This confirmed that Linux could reach the Windows host/gateway.

### Test 2 — Internet Connectivity

```bash
ping -c 4 8.8.8.8
```

Result:

```text
Successful
```

This confirmed:

```text
Linux
  |
  v
172.16.10.1
  |
  v
Windows NAT
  |
  v
Internet
```

The NAT configuration is functioning.

### Test 3 — DNS Resolution

```bash
ping -c 4 google.com
```

Result:

```text
DNS resolution failed
```

This established that basic Internet connectivity works while DNS resolution does not.

---

## 7. Troubleshooting Linux → Domain Controller Connectivity

Linux initially could not reach:

```text
172.16.10.10
```

The Domain Controller could reach Linux, and the Windows firewall was checked.

### Windows Firewall

On Glass-DC1:

```powershell
Get-NetFirewallProfile | Select-Object Name, Enabled
```

Result:

```text
Domain   False
Private  False
Public   False
```

The Windows Firewall was therefore not blocking the test traffic.

### ARP / Neighbor Table

On Linux:

```bash
ip neigh
```

The Domain Controller appeared in the neighbor table:

```text
172.16.10.10 dev eth0
lladdr 00:15:5d:01:f1:00
```

This confirmed that Linux successfully resolved the DC's MAC address.

After retesting:

```bash
ping -c 4 172.16.10.10
```

Result:

```text
4 packets transmitted
4 received
0% packet loss
```

The neighbor state became:

```text
REACHABLE
```

### Routing Verification

```bash
ip route get 172.16.10.10
```

Result:

```text
172.16.10.10 dev eth0 src 172.16.10.30
```

This confirmed that Linux was correctly treating the DC as a local-network destination and was not attempting to send the traffic through the default gateway.

---

## 8. DNS Troubleshooting

Linux is configured to use the Domain Controller as its DNS server:

```text
DNS Server: 172.16.10.10
```

However, DNS resolution failed.

### Testing from Glass-DC1

```powershell
Resolve-DnsName google.com
```

Result:

```text
The timeout period expired
```

Testing specifically against the DC:

```powershell
Resolve-DnsName google.com -Server 172.16.10.10
```

Result:

```text
DNS server failure
```

### DNS Port Verification

DNS was confirmed to be listening on port 53.

```powershell
Get-NetUDPEndpoint -LocalPort 53
```

The DNS service was listening on:

```text
172.16.10.10
127.0.0.1
```

Therefore:

```text
DNS Service Listening:    YES
DNS External Resolution:  NOT WORKING
```

---

# Current State

## Working

- Hyper-V `mavlab` virtual switch
- `172.16.10.0/24` lab network
- Windows NAT
- Linux static IP
- Linux default gateway
- Linux → Windows host connectivity
- Linux → Internet IP connectivity
- Linux → Domain Controller connectivity
- Domain Controller → Linux connectivity
- DNS service listening on port 53

## Still To Configure / Troubleshoot

- Glass-DC1 default gateway
- Glass-SVR1 default gateway
- External DNS resolution through Glass-DC1
- DNS forwarding
- Persistent Netplan file permissions
- Final end-to-end DNS test

---

# Troubleshooting Method Used

The network was tested one layer at a time:

```text
1. Local Network
       |
       v
2. Default Gateway
       |
       v
3. Internet Connectivity
       |
       v
4. DNS Resolution
```

Examples:

```bash
ping -c 4 172.16.10.1
```

Tests the local gateway.

```bash
ping -c 4 8.8.8.8
```

Tests Internet connectivity without relying on DNS.

```bash
ping -c 4 google.com
```

Tests DNS resolution and connectivity.

This approach helps isolate whether a failure is related to:

- IP configuration
- Routing
- Gateway
- NAT
- Firewall
- DNS
- Application/service configuration

---

# Commands Used

## Windows / PowerShell

```powershell
$PSVersionTable.PSVersion

Get-Command New-NetNat

New-NetNat `
    -Name "MavLabNAT" `
    -InternalIPInterfaceAddressPrefix "172.16.10.0/24"

Get-NetNat

Get-NetFirewallProfile | Select-Object Name, Enabled

Get-NetUDPEndpoint -LocalPort 53

Resolve-DnsName google.com

Resolve-DnsName google.com -Server 172.16.10.10
```

## Linux

```bash
ip addr
ip route
ip route get 172.16.10.10
ip neigh
ip neigh show 172.16.10.10

ping -c 4 172.16.10.1
ping -c 4 172.16.10.10
ping -c 4 8.8.8.8
ping -c 4 google.com

sudo netplan get
sudo netplan generate
sudo netplan try
```

---

# Key Concepts Demonstrated

- Hyper-V virtual switches
- Private virtual networking
- IPv4 addressing
- `/24` subnet
- Default gateway
- Static IP configuration
- Routing tables
- ARP / neighbor discovery
- Windows NAT
- PowerShell networking commands
- Netplan
- YAML configuration
- DNS
- DNS port 53
- DNS forwarding
- Network troubleshooting methodology
- Layer-by-layer troubleshooting
- Windows/Linux interoperability

---

# Next Steps

1. Configure the default gateway on Glass-DC1.
2. Verify Glass-DC1 can reach the Internet.
3. Configure and verify DNS forwarding on Glass-DC1.
4. Test external DNS resolution from the DC.
5. Test DNS resolution from Linux1.
6. Configure the gateway on Glass-SVR1.
7. Verify all lab systems have the expected network configuration.
8. Document the final topology and testing results.

---

## Lab Status

**Networking Foundation: IN PROGRESS**

The MavLab private network and NAT infrastructure are operational.

Current blocker:

```text
Glass-DC1 DNS → External DNS
```

The next phase is configuring the Domain Controller's default gateway and completing DNS resolution.