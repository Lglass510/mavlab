## ReaperSOC Lab

This lab documents the remote administration setup for two virtual machines:

- **Rocky Linux**: Linux workstation and SSH client connected to Visual Studio Code.
- **DC1**: Windows domain controller configured to accept SSH connections.

The setup allows Rocky Linux to be managed from VS Code and provides an SSH path to the domain controller for administration and lab work.

## Lab Topology

| System | Role | Connection |
| --- | --- | --- |
| Rocky Linux VM (`reaper1`) | Linux workstation / SSH client | Connected to VS Code through Remote - SSH |
| DC1 VM | Windows domain controller | SSH target from Rocky Linux as `GLASSLAB\Administrator` |

Keep the VM hostnames, IP addresses, usernames, and credentials in your private lab notes. Do not commit passwords, private keys, or other secrets to this repository.

## Prerequisites

- Rocky Linux and DC1 virtual machines running on the same reachable virtual network
- Administrative access to both VMs
- SSH enabled and running on both systems
- Visual Studio Code installed on the host computer
- The VS Code **Remote - SSH** extension installed
- A working SSH key or other approved authentication method

## Configuration Summary

### Rocky Linux (`reaper1`)

Rocky Linux was configured as the primary SSH client. Its hostname is **reaper1**, and it was connected to VS Code using Remote - SSH. After connecting, VS Code can open a remote Rocky Linux window and run terminals, edit files, and use development tools on the VM.

### DC1 (`GLASSLAB\Administrator`)

The domain controller VM was configured for SSH access using the domain-qualified account **GLASSLAB\Administrator**. From Rocky Linux, the connection can be tested with:

```bash
ssh 'GLASSLAB\\Administrator'@<ip>
```

Replace `<dc1-hostname-or-ip>` with the address used in the lab. The quotes preserve the backslash in the domain-qualified username.

### VS Code Remote - SSH

On the host computer:

1. Install or enable the **Remote - SSH** extension.
2. Open the Command Palette and select **Remote-SSH: Connect to Host...**.
3. Select the Rocky Linux SSH host, or enter its SSH connection details.
4. Authenticate when prompted.
5. Open a folder on Rocky Linux in the remote VS Code window.

An SSH host entry can be kept in the user's SSH configuration file. A generic example is:

```sshconfig
Host rocky-linux
	HostName reaper1
	User <rocky-username>
	IdentityFile <path-to-private-key>
```

Use a private key with appropriate local permissions and keep the key outside the repository.

## Verification

From Rocky Linux, verify the local system and the DC1 connection:

```bash
hostname
ssh 'GLASSLAB\\Administrator'@<ip>
```

The first command should report `reaper1`. After connecting to DC1, confirm that the remote shell identifies the expected domain controller. In VS Code, confirm that the status bar shows the Rocky Linux SSH host and that a terminal opens in the Rocky Linux environment.

## Troubleshooting

### SSH connection refused

- Confirm the target VM is powered on and reachable.
- Confirm the SSH service is running on the target.
- Check that the configured SSH port is allowed through the target firewall.
- Verify the hostname resolves correctly, or use the VM's IP address.

### Permission denied

- Confirm the username is correct for the target operating system.
- Verify that the public key is installed for the intended account.
- Check that the client is using the expected private key.
- If password authentication is enabled for the lab, confirm the account is permitted to log in through SSH.

### VS Code cannot connect to Rocky Linux

- Test the same host entry from a terminal with `ssh rocky-linux`.
- Review the Remote - SSH output panel for the failing step.
- Confirm that Rocky Linux has network access and that its SSH server is running.
- Reconnect after correcting the SSH host entry or authentication settings.

## Security Notes

- Use SSH keys where possible and protect private keys with a passphrase.
- Use separate lab accounts with only the permissions required for the exercise.
- Restrict SSH access to the lab network.
- Do not expose the domain controller's SSH service directly to the public internet.
- Remove or rotate temporary lab credentials when the environment is no longer needed.

## Screenshots

Screenshots were not captured during the configuration. The setup can be demonstrated with the successful Rocky Linux Remote - SSH session in VS Code and a working SSH session from Rocky Linux to DC1.
