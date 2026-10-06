<#
.SYNOPSIS
    Create the OU structure for the soc.local lab domain.
.DESCRIPTION
    Idempotent: skips OUs that already exist. Run on the DC as a Domain Admin.
.EXAMPLE
    .\New-LabOU.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$DomainDN = "DC=soc,DC=local"
)

Import-Module ActiveDirectory

function New-OUIfMissing {
    param([string]$Name, [string]$Path)
    $dn = "OU=$Name,$Path"
    if (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$dn'" -ErrorAction SilentlyContinue) {
        Write-Verbose "Exists: $dn"
    }
    elseif ($PSCmdlet.ShouldProcess($dn, "Create OU")) {
        New-ADOrganizationalUnit -Name $Name -Path $Path -ProtectedFromAccidentalDeletion $true
        Write-Host "Created: $dn"
    }
}

# Root
New-OUIfMissing -Name "SOC" -Path $DomainDN
$root = "OU=SOC,$DomainDN"

# Second level
"Users","Groups","Workstations","Servers" | ForEach-Object { New-OUIfMissing -Name $_ -Path $root }

# Department OUs under Users
$usersOU = "OU=Users,$root"
"IT","Finance","HR" | ForEach-Object { New-OUIfMissing -Name $_ -Path $usersOU }

Write-Host "OU structure ready." -ForegroundColor Green
