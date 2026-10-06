<#
.SYNOPSIS
    Report enabled AD accounts with no logon in the last N days.
.DESCRIPTION
    Account-hygiene check: stale accounts are a common attack path. Read-only.
.EXAMPLE
    .\Get-StaleAccounts.ps1 -Days 90 | Export-Csv stale.csv -NoTypeInformation
#>
[CmdletBinding()]
param(
    [int]$Days = 90
)

Import-Module ActiveDirectory
$cutoff = (Get-Date).AddDays(-$Days)

Get-ADUser -Filter {Enabled -eq $true} -Properties LastLogonDate, Department |
    Where-Object { $_.LastLogonDate -ne $null -and $_.LastLogonDate -lt $cutoff } |
    Select-Object SamAccountName, Name, Department, LastLogonDate |
    Sort-Object LastLogonDate
