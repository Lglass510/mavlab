# Active Directory Domain Build

## Domain Controller

Server Name:
Glass-DC1

Operating System:
Windows Server 2025

## Roles Installed

- Active Directory Domain Services
- DNS Server

## Configuration Completed

- Installed Windows Server
- Configured static IP address
- Renamed server to Glass-DC1
- Installed DNS role
- Installed Active Directory Domain Services
- Promoted server to Domain Controller

## Purpose

Glass-DC1 provides Active Directory Domain Services and DNS for the homelab environment.
## Validation

Verified:

- Static IP configuration
- DNS points to domain controller
- AD DS service running
- DNS service running
- Netlogon service running
- Active Directory Web Services running

## Organizational Units Created

Created the following OUs:

- Lab Employees
- Lab Computers
- Lab Servers
- Lab Admin Accounts
- Groups
- Lab Service Accounts

## Purpose

The OU structure separates users, computers, servers, administrative accounts, groups, and service accounts to allow targeted Group Policy management and delegation.