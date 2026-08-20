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

Linux1 was configured to use the Domain Controller as its DNS server:

```text
DNS Server: 172.16.10.10
```

Initial DNS resolution failed:

```bash
ping -c 4 google.com
```

Result:

```text
Temporary failure in name resolution
```

This established that Internet connectivity was working at the IP layer, but DNS resolution was not.

### DNS Service Verification

On Glass-DC1, DNS was verified to be listening on port 53:

```powershell
Get-NetUDPEndpoint -LocalPort 53
```

DNS was listening on:

```text
172.16.10.10
127.0.0.1
```

Therefore:

```text
DNS Service Listening:    YES
External DNS Resolution:  NOT WORKING
```

### Domain Controller Gateway

Glass-DC1 initially had no IPv4 default gateway.

Verification:

```powershell
Get-NetIPConfiguration
```

Initial configuration:

```text
IPv4 Address:         172.16.10.10
IPv4 Default Gateway: [blank]
DNS Server:           127.0.0.1
```

A default route was added:

```powershell
New-NetRoute `
    -InterfaceAlias "Ethernet" `
    -DestinationPrefix "0.0.0.0/0" `
    -NextHop "172.16.10.1"
```

The gateway was then verified:

```text
IPv4 Default Gateway: 172.16.10.1
```

### Gateway and Internet Testing

The Domain Controller successfully reached the Windows NAT gateway:

```powershell
ping 172.16.10.1
```

Result:

```text
Successful
```

Internet connectivity was then tested without relying on DNS:

```powershell
ping 8.8.8.8
```

Result:

```text
Successful
```

This proved that the Domain Controller had a functional path to the Internet.

The troubleshooting path was now:

```text
Glass-DC1
172.16.10.10
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

### DNS Forwarder Investigation

The configured DNS forwarder was examined:

```powershell
Get-DnsServerForwarder
```

The server had the following forwarder configured:

```text
172.31.240.1
```

The forwarder was tested directly:

```powershell
ping 172.31.240.1
```

Result:

```text
Request timed out
```

This identified the configured DNS forwarder as unreachable from the lab network.

### DNS Forwarder Replacement

The unreachable forwarder was removed:

```powershell
Remove-DnsServerForwarder `
    -IPAddress 172.31.240.1 `
    -Force
```

A new external DNS forwarder was configured:

```powershell
Add-DnsServerForwarder `
    -IPAddress 1.1.1.1 `
    -PassThru
```

The configuration was verified:

```powershell
Get-DnsServerForwarder
```

Result:

```text
IPAddress
---------
1.1.1.1
```

### External DNS Verification

The external DNS server was tested directly:

```powershell
Resolve-DnsName google.com -Server 1.1.1.1
```

The query successfully returned DNS records.

The Domain Controller's DNS service was then tested:

```powershell
Resolve-DnsName google.com -Server 172.16.10.10
```

The query successfully resolved.

Finally, the Domain Controller's default DNS configuration was tested:

```powershell
Resolve-DnsName google.com
```

External DNS resolution was successful.

### Linux DNS Verification

Linux1 uses the Domain Controller as its DNS server:

```text
172.16.10.10
```

After correcting the Domain Controller's gateway and DNS forwarding configuration:

```bash
ping -c 4 google.com
```

DNS resolution successfully worked from Linux1.

This verified the complete DNS path:

```text
Linux1
172.16.10.30
      |
      | DNS Query
      v
Glass-DC1
172.16.10.10
      |
      | DNS Forwarder
      v
1.1.1.1
      |
      v
Internet DNS
      |
      v
google.com
```

---

## 9. Current State

### Working

- Hyper-V `mavlab` virtual switch
- `172.16.10.0/24` private lab network
- Windows NAT
- Linux static IP
- Linux default gateway
- Linux → Windows host connectivity
- Linux → Internet IP connectivity
- Linux → Domain Controller connectivity
- Domain Controller → Linux connectivity
- Domain Controller default gateway
- DNS service listening on port 53
- DNS forwarding through `1.1.1.1`
- Domain Controller → external DNS resolution
- Linux → external DNS resolution

### Still To Configure

- Glass-SVR2 default gateway
- Verify Glass-SVR2 Internet connectivity
- Verify Glass-SVR2 DNS configuration
- Verify Glass-SVR2 can resolve external DNS
- Make sure the DC gateway configuration is persistent
- Resolve Netplan configuration file permission warning
- Perform final end-to-end network verification

---

## 10. Troubleshooting Method Used

The network was tested one layer at a time rather than changing multiple configurations simultaneously.

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
4. DNS Service
       |
       v
5. External DNS Resolution
```

### Layer 1 — Local Connectivity

```bash
ping -c 4 172.16.10.10
```

Verified Linux1 could communicate with the Domain Controller.

### Layer 2 — Gateway

```bash
ping -c 4 172.16.10.1
```

Verified Linux1 could reach the Windows NAT gateway.

The same test was performed from Glass-DC1 after adding its default gateway.

### Layer 3 — Internet Connectivity

```bash
ping -c 4 8.8.8.8
```

This tests Internet connectivity without depending on DNS.

### Layer 4 — DNS Service

```powershell
Get-NetUDPEndpoint -LocalPort 53
```

Verified that the DNS service was listening.

### Layer 5 — External DNS

```powershell
Resolve-DnsName google.com
```

Verified whether the DNS server could resolve external names.

This troubleshooting methodology helps isolate failures related to:

- IP configuration
- Routing
- Default gateway
- NAT
- Firewall
- DNS service
- DNS forwarding
- Application/service configuration

---

## 11. Commands Used

### Windows / PowerShell

```powershell
$PSVersionTable.PSVersion

Get-Command New-NetNat

New-NetNat `
    -Name "MavLabNAT" `
    -InternalIPInterfaceAddressPrefix "172.16.10.0/24"

Get-NetNat

Get-NetIPConfiguration

New-NetRoute `
    -InterfaceAlias "Ethernet" `
    -DestinationPrefix "0.0.0.0/0" `
    -NextHop "172.16.10.1"

Get-NetFirewallProfile |
    Select-Object Name, Enabled

Get-NetUDPEndpoint -LocalPort 53

Get-DnsServerForwarder

Get-DnsServerRootHint

Remove-DnsServerForwarder `
    -IPAddress 172.31.240.1 `
    -Force

Add-DnsServerForwarder `
    -IPAddress 1.1.1.1 `
    -PassThru

Resolve-DnsName google.com

Resolve-DnsName google.com `
    -Server 172.16.10.10

Resolve-DnsName google.com `
    -Server 1.1.1.1
```

### Linux

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

nslookup google.com

resolvectl status
```

---

## 12. Key Concepts Demonstrated

- Hyper-V virtual switches
- Private virtual networking
- IPv4 addressing
- `/24` subnetting
- Default gateways
- Static IP configuration
- Routing tables
- Default routes
- ARP / neighbor discovery
- Windows NAT
- PowerShell networking commands
- PowerShell 5.1 vs PowerShell 7
- Netplan
- YAML configuration
- DNS
- DNS port 53
- DNS forwarders
- DNS root hints
- External DNS resolution
- Windows DNS Server
- Linux DNS client configuration
- Windows/Linux interoperability
- Network troubleshooting methodology
- Layer-by-layer troubleshooting

---

## 13. Next Steps

1. Configure the default gateway on Glass-SVR2.
2. Verify Glass-SVR2 can reach `172.16.10.1`.
3. Verify Glass-SVR2 can reach `8.8.8.8`.
4. Configure Glass-SVR2 to use `172.16.10.10` for DNS.
5. Verify Glass-SVR2 can resolve external DNS.
6. Make the Glass-DC1 gateway configuration persistent.
7. Correct the Netplan file permissions warning on Linux1.
8. Perform final end-to-end connectivity testing.
9. Capture screenshots of the completed network configuration.
10. Document the final MavLab topology.

---

## Lab Status

**Networking Foundation: OPERATIONAL**

The MavLab private network, Windows NAT, routing, Domain Controller connectivity, DNS forwarding, and Linux external DNS resolution are operational.

The remaining work is primarily configuration cleanup and bringing Glass-SVR2 into the completed network.
