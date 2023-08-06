
<#
.NOTES
    Author:  @kengentenerende

    Summary: Powershell Script to Automate SSH Public Key Login.

.PARAMETER -u
     Username of the Remote Server.

.PARAMETER -ip
     IP Address of the Remote Server.

.PARAMETER -akey
     The path to the Public key file.
#>

param(
    [Parameter(Mandatory=$true)][string]$u,
    [Parameter(Mandatory=$true)][string]$ip,
    [Parameter(Mandatory=$true)][string]$akey
)


$resultHost = $u+"@"+$ip
$currentDir = $PWD
function Get-Param{
param(
    [string]$u,
    [string]$ip,
    [string]$akey
)
    "Machine Username: $u"
    "Machine IP Address: $ip"
    "Authorized Keys: $pkey"
    "Hostname: $resultHost"

}

Get-Param @PSBoundParameters


#Automation to Register Private Key on Authorized Keys
type $akey | ssh $resultHost "mkdir -p ~/.ssh; chmod 700 ~/.ssh; touch ~/.ssh/authorized_keys; cat >> ~/.ssh/authorized_keys";

Write-Host "`n[+] Operation Complete" -ForegroundColor Green;

