<#
.SYNOPSIS
    Bulk-create AD users from a CSV, place them in the right OU and group.
.DESCRIPTION
    Reads users.csv (FirstName,LastName,SamAccountName,Department,Title,Group).
    Idempotent: skips users that already exist. Creates the target group if missing.
    Initial password must be changed at first logon.
.EXAMPLE
    .\New-LabUsers.ps1 -CsvPath .\users.csv -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$CsvPath = ".\users.csv",
    [string]$DomainDN = "DC=soc,DC=local",
    [string]$UpnSuffix = "soc.local"
)

Import-Module ActiveDirectory

$initialPassword = Read-Host "Initial password for new users" -AsSecureString
$usersOU = "OU=Users,OU=SOC,$DomainDN"
$groupsOU = "OU=Groups,OU=SOC,$DomainDN"

Import-Csv $CsvPath | ForEach-Object {
    $sam = $_.SamAccountName
    $targetOU = "OU=$($_.Department),$usersOU"

    # Ensure the department OU exists
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$targetOU'" -ErrorAction SilentlyContinue)) {
        Write-Warning "OU missing: $targetOU - run New-LabOU.ps1 first. Skipping $sam."
        return
    }

    # Ensure the group exists
    if (-not (Get-ADGroup -Filter "Name -eq '$($_.Group)'" -ErrorAction SilentlyContinue)) {
        if ($PSCmdlet.ShouldProcess($_.Group, "Create group")) {
            New-ADGroup -Name $_.Group -GroupScope Global -GroupCategory Security -Path $groupsOU
        }
    }

    # Create the user
    if (Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue) {
        Write-Verbose "User exists: $sam"
    }
    elseif ($PSCmdlet.ShouldProcess($sam, "Create user")) {
        New-ADUser `
            -Name "$($_.FirstName) $($_.LastName)" `
            -GivenName $_.FirstName -Surname $_.LastName `
            -SamAccountName $sam `
            -UserPrincipalName "$sam@$UpnSuffix" `
            -Title $_.Title -Department $_.Department `
            -Path $targetOU `
            -AccountPassword $initialPassword `
            -ChangePasswordAtLogon $true `
            -Enabled $true
        Add-ADGroupMember -Identity $_.Group -Members $sam
        Write-Host "Created $sam in $($_.Department) ($($_.Group))"
    }
}

Write-Host "Done." -ForegroundColor Green
