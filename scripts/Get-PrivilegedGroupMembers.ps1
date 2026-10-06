<#
.SYNOPSIS
    Audit members of privileged AD groups and export to CSV.
.DESCRIPTION
    Lists effective (recursive) members of Tier-0 groups. Read-only.
    Run regularly and diff the output to catch unexpected privilege changes
    (pairs with Wazuh rule 100100 in the SOC lab).
.EXAMPLE
    .\Get-PrivilegedGroupMembers.ps1 | Export-Csv priv-members.csv -NoTypeInformation
#>
[CmdletBinding()]
param(
    [string[]]$Groups = @("Domain Admins","Enterprise Admins","Administrators","Schema Admins")
)

Import-Module ActiveDirectory

foreach ($g in $Groups) {
    try {
        Get-ADGroupMember -Identity $g -Recursive |
            Get-ADUser -Properties Enabled, LastLogonDate |
            Select-Object @{N='Group';E={$g}}, SamAccountName, Name, Enabled, LastLogonDate
    }
    catch {
        Write-Warning "Could not read group '$g': $_"
    }
}
