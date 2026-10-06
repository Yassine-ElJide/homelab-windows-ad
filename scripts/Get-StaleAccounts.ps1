<#
.SYNOPSIS
    Report enabled AD accounts with no logon in the last N days.
.DESCRIPTION
    Account-hygiene check: stale accounts are a common attack path. Read-only.
    Also reports accounts that never logged on and were created more than N days ago.
    LastLogonDate is replicated with up to ~14 days of lag, so use N >= 30.
.EXAMPLE
    .\Get-StaleAccounts.ps1 -Days 90 | Export-Csv stale.csv -NoTypeInformation
#>
[CmdletBinding()]
param(
    [ValidateRange(1, 3650)]
    [int]$Days = 90
)

Import-Module ActiveDirectory
$cutoff = (Get-Date).AddDays(-$Days)

Get-ADUser -Filter 'Enabled -eq $true' -Properties LastLogonDate, WhenCreated, Department |
    Where-Object {
        ($_.LastLogonDate -and $_.LastLogonDate -lt $cutoff) -or
        (-not $_.LastLogonDate -and $_.WhenCreated -lt $cutoff)
    } |
    Select-Object SamAccountName, Name, Department, LastLogonDate, WhenCreated,
        @{N='Status';E={ if ($_.LastLogonDate) { 'Inactive' } else { 'NeverLoggedOn' } }} |
    Sort-Object LastLogonDate
