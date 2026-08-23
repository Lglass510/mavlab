# Linux Networking

## Linux1 Overview

Linux1 is an Ubuntu Linux Server virtual machine running within the MavLab Hyper-V environment.

| Configuration          | Value               |
| ---------------------- | ------------------- |
| Hostname               | `Linux1`            |
| Operating System       | Ubuntu Linux Server |
| IPv4 Address           | `172.16.10.30/24`   |
| Network Interface      | `eth0`              |
| Hyper-V Virtual Switch | `mavlab`            |
| Network                | `172.16.10.0/24`    |

## Network Configuration

Linux1 was configured with a static IPv4 address on the MavLab `172.16.10.0/24` network.

### IP Address Verification

The network interfaces and assigned addresses were checked using:

```bash
ip addr
```

Linux1 was configured with:

```text
172.16.10.30/24
```

### Routing Verification

The routing table was checked using:

```bash
ip route
```

The resulting route was:

```text
172.16.10.0/24 dev eth0 proto kernel scope link src 172.16.10.30
```

![Linux1 Routing Table](screenshots/LinuxIPRouteOutput.png)

This indicates that Linux recognizes `172.16.10.0/24` as a directly connected network and sends traffic for that subnet through `eth0`.

### Route Components

| Component          | Meaning                                         |
| ------------------ | ----------------------------------------------- |
| `172.16.10.0/24`   | Destination network                             |
| `dev eth0`         | Network interface used                          |
| `proto kernel`     | Route automatically created by the Linux kernel |
| `scope link`       | Destination is directly connected               |
| `src 172.16.10.30` | Source address used by Linux                    |

## Connectivity Testing

Linux1 was used to test connectivity with other systems on the MavLab network.

### Test DC1

```bash
ping -c 4 172.16.10.10
```

### Test SRV2

```bash
ping -c 4 172.16.10.20
```

These tests verify Layer 3 connectivity between Linux1 and the other virtual machines on the `172.16.10.0/24` network.

## Neighbor Discovery

Linux neighbor information can be viewed using:

```bash
ip neigh
```

This provides information about neighboring devices and their resolved Layer 2 addresses.

## Networking Skills Practiced

* Linux IPv4 configuration
* Linux routing tables
* Network interface management
* Layer 3 connectivity testing
* Neighbor discovery
* Basic Linux network troubleshooting
* Understanding directly connected routes
* Using Linux networking utilities

## Next Steps

* Configure Linux1 to use the MavLab DNS infrastructure
* Verify hostname resolution
* Configure SSH for remote administration
* Practice Linux service administration
* Continue Bash administration
* Integrate Linux1 with the wider MavLab infrastructure


