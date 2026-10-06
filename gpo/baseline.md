# GPO security baseline

Baseline applied in the lab, with the reasoning and the GPMC path for each setting. Values chosen to be defensible in an interview, not just "max everything".

## 1. Password & Account Lockout (scope: Domain)
`Computer Configuration > Policies > Windows Settings > Security Settings > Account Policies`

| Setting | Value | Why |
| --- | --- | --- |
| Minimum password length | 14 | Aligns with CIS / ANSSI guidance |
| Password history | 24 | Prevents reuse |
| Maximum password age | 0 (never expires) | Modern guidance (NIST, ANSSI) favours length and no forced rotation unless compromise |
| Account lockout threshold | 5 attempts | Slows brute force (T1110) |
| Lockout duration / reset | 15 min | Balances security and help-desk load |

## 2. Advanced Audit Policy (scope: Domain Controllers)
`...Security Settings > Advanced Audit Policy Configuration > Audit Policies`

| Subcategory | Setting | Feeds |
| --- | --- | --- |
| Logon | Success, Failure | 4624 / 4625 |
| Kerberos Service Ticket Operations | Success, Failure | 4769 (Kerberoasting rule 100110) |
| Kerberos Authentication Service | Success, Failure | 4768 / 4771 (password spraying) |
| Credential Validation | Success, Failure | 4776 (NTLM spraying) |
| Security Group Management | Success | 4728/4732/4756 (rule 100100) |
| Other Account Management Events | Success | - |

Also set `Security Options > Audit: Force audit policy subcategory settings` to **Enabled** so the advanced audit policy overrides the legacy one.

> This GPO is the prerequisite for the whole SOC lab. Without it the detections have no events.

## 3. USB Storage Restriction (scope: Workstations)
`Computer Configuration > Policies > Administrative Templates > System > Removable Storage Access`
- *Removable Disks: Deny write access* → **Enabled** (mitigates T1052 exfiltration over USB)

## 4. Disable SMBv1 (scope: All)
`Administrative Templates > MS Security Guide > Configure SMB v1 server` → **Disabled** and `Configure SMB v1 client driver` → **Disable driver**
- The MS Security Guide templates come from the Microsoft Security Compliance Toolkit (`SecGuide.admx/adml`), copy them to the Central Store first.
- Removes a legacy, exploitable protocol (T1210).

## 5. Interactive Screen Lock (scope: Workstations)
`...Security Options > Interactive logon: Machine inactivity limit` → **600 seconds**
- Computer setting, so the GPO is linked to the Workstations OU. Limits unattended-session abuse.

## Verify after applying
```powershell
gpupdate /force
gpresult /h gpreport.html          # effective policy on a client
auditpol /get /category:*          # confirm audit subcategories
```
