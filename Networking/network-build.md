# Network Build and Troubleshooting

## Network Redesign

The MavLab network was redesigned to use a dedicated Hyper-V virtual switch named `mavlab`.

The previous configuration relied on the Hyper-V Default Switch. The new configuration provides a dedicated network for the lab environment and allows the virtual machines to communicate directly on the same subnet.

## Current Network Configuration

| VM     | Role                         | IPv4 Address   | Subnet Mask     | Virtual Switch |
| ------ | ---------------------------- | -------------- | --------------- | -------------- |
| DC1    | Domain Controller / DNS      | `172.16.10.10` | `255.255.255.0` | `mavlab`       |
| SRV2   | Windows Server Member Server | `172.16.10.20` | `255.255.255.0` | `mavlab`       |
| Linux1 | Ubuntu Linux Server          | `172.16.10.30` | `/24`           | `mavlab`       |

**Network:** `172.16.10.0/24`

**Broadcast:** `172.16.10.255`

Because all three systems are on the same `/24` subnet, they can communicate directly for local subnet traffic without requiring a default gateway.

## Network Topology

```text
                         Hyper-V Host
                              |
                        mavlab Switch
                              |
              +---------------+---------------+
              |               |               |
             DC1             SRV2           Linux1
        172.16.10.10    172.16.10.20    172.16.10.30
              |               |               |
              +---------------+---------------+
                       172.16.10.0/24
```

## Connectivity Troubleshooting

Initially, all three virtual machines were configured within the same subnet and connected to the same `mavlab` virtual switch, but they were unable to successfully ping one another.

Troubleshooting was performed from the lower layers of the network stack upward.

### IP Configuration

The IP configuration was verified on each system:

| System | Address           |
| ------ | ----------------- |
| DC1    | `172.16.10.10/24` |
| SRV2   | `172.16.10.20/24` |
| Linux1 | `172.16.10.30/24` |

This confirmed that all systems were correctly addressed within the same `172.16.10.0/24` network.

### ARP Verification

ARP was checked on DC1 using:

```powershell
arp -a
```

The ARP table contained dynamic entries for the other lab systems:

```text
172.16.10.20    00-15-5d-01-f1-01    dynamic
172.16.10.30    00-15-5d-01-f1-02    dynamic
```

This demonstrated that DC1 was successfully resolving the IPv4 addresses of the other virtual machines to their MAC addresses.

ARP resolution confirmed that Layer 2 connectivity was functioning across the Hyper-V `mavlab` switch.

### Linux Routing Verification

Linux1 was checked using:

```bash
ip route
```

The resulting route was:

```text
172.16.10.0/24 dev eth0 proto kernel scope link src 172.16.10.30
```

![Linux1 Routing Table](../Linux/screenshots/LinuxIPRouteOutput.png)

This indicates that Linux recognizes `172.16.10.0/24` as a directly connected network and sends traffic for that subnet through `eth0`.

### Route Components

| Component          | Meaning                                         |
| ------------------ | ----------------------------------------------- |
| `172.16.10.0/24`   | Destination network                             |
| `dev eth0`         | Network interface used                          |
| `proto kernel`     | Route automatically created by the Linux kernel |
| `scope link`       | Destination is directly connected               |
| `src 172.16.10.30` | Source address used by Linux                    |

## Firewall Troubleshooting

The initial ICMP failures were investigated after confirming that the machines could resolve one another through ARP.

Windows Firewall configuration was identified as the factor affecting ICMP communication.

After addressing the firewall configuration, the systems were able to communicate successfully.

## Connectivity Verification

Linux1 successfully pinged DC1:

```text
11 packets transmitted, 11 received, 0% packet loss
```

The lab now has confirmed:

* Layer 2 connectivity
* ARP resolution
* Layer 3 connectivity
* Local subnet routing
* ICMP communication between virtual machines

## Commands Practiced

### Windows

View IP configuration:

```powershell
ipconfig
```

Test ICMP connectivity:

```powershell
ping 172.16.10.20
ping 172.16.10.30
```

Test network connectivity and TCP ports:

```powershell
Test-NetConnection 172.16.10.20
```

View the ARP cache:

```powershell
arp -a
```

View the routing table:

```powershell
route print
```

View Windows Firewall profiles:

```powershell
Get-NetFirewallProfile
```

### Linux

View network interfaces and IP addresses:

```bash
ip addr
```

View the routing table:

```bash
ip route
```

View neighboring devices:

```bash
ip neigh
```

Test ICMP connectivity:

```bash
ping -c 4 172.16.10.10
ping -c 4 172.16.10.20
```

## Networking Concepts Practiced

This troubleshooting exercise reinforced the relationship between:

```text
IP Configuration
      ↓
Virtual Switching
      ↓
Layer 2 / MAC Addresses
      ↓
ARP
      ↓
Layer 3 / IP Routing
      ↓
Firewall
      ↓
Network Services
```

A matching subnet alone does not guarantee communication. Successful connectivity depends on the virtual network, network interfaces, ARP resolution, routing, firewall configuration, and the services being tested.

## Next Steps

With basic network connectivity established, the next phase of the lab will focus on higher-level infrastructure services:

* Configure and verify DNS across the lab
* Verify SRV2 domain communication with DC1
* Configure Linux1 to use the lab DNS infrastructure
* Test hostname resolution between systems
* Verify Active Directory functionality
* Practice Group Policy administration
* Test SMB and remote administration
* Continue PowerShell automation
* Document infrastructure changes and troubleshooting procedures
