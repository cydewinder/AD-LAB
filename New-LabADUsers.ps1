#Requires -Version 5.1
<#
.SYNOPSIS
    Creates 50 realistic lab users in Active Directory remotely.

.DESCRIPTION
    Connects to a remote Domain Controller via PowerShell remoting or RSAT
    and creates 50 users spread across multiple OUs with varied group memberships,
    departments, and titles — suitable for AD security lab work.

.PARAMETER DCHostname
    FQDN or IP of the target Domain Controller.

.PARAMETER DomainDN
    Distinguished Name of the domain root. e.g. DC=lab,DC=local

.PARAMETER Credential
    PSCredential for a Domain Admin account.

.PARAMETER UseRemoting
    If specified, uses Invoke-Command (PSRemoting) instead of local RSAT.
    Use this when your workstation is NOT domain-joined.

.EXAMPLE
    # Using PSRemoting (machine not domain-joined):
    $cred = Get-Credential
    .\New-LabADUsers.ps1 -DCHostname "192.168.10.10" -DomainDN "DC=lab,DC=local" -Credential $cred -UseRemoting

.EXAMPLE
    # Using RSAT (machine is domain-joined):
    .\New-LabADUsers.ps1 -DCHostname "DC01.lab.local" -DomainDN "DC=lab,DC=local" -Credential (Get-Credential)

.NOTES
    Author  : AD Lab Builder
    Version : 1.0
    Requires: RSAT AD PowerShell module OR PSRemoting enabled on DC
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory)]
    [string]$DCHostname,

    [Parameter(Mandatory)]
    [string]$DomainDN,           # e.g. DC=lab,DC=local

    [Parameter(Mandatory)]
    [System.Management.Automation.PSCredential]$Credential,

    [switch]$UseRemoting         # Use PSRemoting instead of RSAT
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# USER DATA — 50 users across departments
# Format: FirstName, LastName, Department, Title, OU leaf name
# ---------------------------------------------------------------------------
$UserData = @(
    # IT Department
    @{ First='James';    Last='Holloway';   Dept='IT';          Title='Systems Administrator';     OU='IT' },
    @{ First='Rachel';   Last='Nguyen';     Dept='IT';          Title='Network Engineer';          OU='IT' },
    @{ First='Marcus';   Last='Ellis';      Dept='IT';          Title='Security Analyst';          OU='IT' },
    @{ First='Priya';    Last='Sharma';     Dept='IT';          Title='Help Desk Technician';      OU='IT' },
    @{ First='Derek';    Last='Okafor';     Dept='IT';          Title='Cloud Engineer';            OU='IT' },
    @{ First='Sophia';   Last='Brennan';    Dept='IT';          Title='DevOps Engineer';           OU='IT' },
    @{ First='Tyler';    Last='Watts';      Dept='IT';          Title='Database Administrator';    OU='IT' },

    # Finance Department
    @{ First='Karen';    Last='Mitchell';   Dept='Finance';     Title='Senior Accountant';         OU='Finance' },
    @{ First='Brian';    Last='Kowalski';   Dept='Finance';     Title='Financial Analyst';         OU='Finance' },
    @{ First='Angela';   Last='Torres';     Dept='Finance';     Title='Payroll Specialist';        OU='Finance' },
    @{ First='Samuel';   Last='Park';       Dept='Finance';     Title='Budget Analyst';            OU='Finance' },
    @{ First='Linda';    Last='Reyes';      Dept='Finance';     Title='Controller';                OU='Finance' },
    @{ First='Gary';     Last='Patel';      Dept='Finance';     Title='Accounts Receivable';       OU='Finance' },

    # HR Department
    @{ First='Diana';    Last='Whitfield';  Dept='HR';          Title='HR Manager';                OU='HR' },
    @{ First='Carlos';   Last='Mendez';     Dept='HR';          Title='Recruiter';                 OU='HR' },
    @{ First='Natalie';  Last='O''Brien';   Dept='HR';          Title='HR Generalist';             OU='HR' },
    @{ First='Eric';     Last='Johansson';  Dept='HR';          Title='Benefits Coordinator';      OU='HR' },
    @{ First='Tiffany';  Last='Brooks';     Dept='HR';          Title='Training Specialist';       OU='HR' },

    # Sales Department
    @{ First='Connor';   Last='Walsh';      Dept='Sales';       Title='Account Executive';         OU='Sales' },
    @{ First='Melissa';  Last='Chen';       Dept='Sales';       Title='Sales Manager';             OU='Sales' },
    @{ First='Jason';    Last='Dubois';     Dept='Sales';       Title='Inside Sales Rep';          OU='Sales' },
    @{ First='Yara';     Last='Hussain';    Dept='Sales';       Title='Regional Sales Director';   OU='Sales' },
    @{ First='Patrick';  Last='Flanagan';   Dept='Sales';       Title='Business Dev Manager';      OU='Sales' },
    @{ First='Stephanie';Last='Grant';      Dept='Sales';       Title='Account Manager';           OU='Sales' },

    # Operations Department
    @{ First='Vincent';  Last='Morales';    Dept='Operations';  Title='Operations Manager';        OU='Operations' },
    @{ First='Amy';      Last='Lawson';     Dept='Operations';  Title='Logistics Coordinator';     OU='Operations' },
    @{ First='Kevin';    Last='Nakamura';   Dept='Operations';  Title='Supply Chain Analyst';      OU='Operations' },
    @{ First='Brenda';   Last='Fitzgerald'; Dept='Operations';  Title='Facilities Manager';        OU='Operations' },
    @{ First='Omar';     Last='Hassan';     Dept='Operations';  Title='Warehouse Supervisor';      OU='Operations' },
    @{ First='Claire';   Last='Bergström';  Dept='Operations';  Title='Process Improvement Lead';  OU='Operations' },

    # Legal Department
    @{ First='Howard';   Last='Kessler';    Dept='Legal';       Title='Corporate Counsel';         OU='Legal' },
    @{ First='Vanessa';  Last='Adeyemi';    Dept='Legal';       Title='Compliance Officer';        OU='Legal' },
    @{ First='Simon';    Last='Blackwell';  Dept='Legal';       Title='Paralegal';                 OU='Legal' },

    # Executive / Leadership
    @{ First='Margaret'; Last='Caldwell';   Dept='Executive';   Title='Chief Executive Officer';   OU='Executives' },
    @{ First='Richard';  Last='Thornton';   Dept='Executive';   Title='Chief Financial Officer';   OU='Executives' },
    @{ First='Susan';    Last='Yamamoto';   Dept='Executive';   Title='Chief Information Officer'; OU='Executives' },
    @{ First='Franklin'; Last='Osei';       Dept='Executive';   Title='Chief Operating Officer';   OU='Executives' },

    # Service Accounts (intentionally privileged for lab attack scenarios)
    @{ First='svc';      Last='backup';     Dept='Service';     Title='Backup Service Account';    OU='ServiceAccounts' },
    @{ First='svc';      Last='deploy';     Dept='Service';     Title='Deployment Service Account';OU='ServiceAccounts' },
    @{ First='svc';      Last='monitor';    Dept='Service';     Title='Monitoring Service Account';OU='ServiceAccounts' },
    @{ First='svc';      Last='sql';        Dept='Service';     Title='SQL Service Account';       OU='ServiceAccounts' },
    @{ First='svc';      Last='web';        Dept='Service';     Title='Web Application Account';   OU='ServiceAccounts' },

    # Marketing
    @{ First='Natasha';  Last='Ivanova';    Dept='Marketing';   Title='Marketing Director';        OU='Marketing' },
    @{ First='Daniel';   Last='Kwon';       Dept='Marketing';   Title='Content Strategist';        OU='Marketing' },
    @{ First='Felicia';  Last='Drummond';   Dept='Marketing';   Title='Social Media Manager';      OU='Marketing' },
    @{ First='Aaron';    Last='Petrov';     Dept='Marketing';   Title='Graphic Designer';          OU='Marketing' },

    # Engineering / R&D
    @{ First='Isabel';   Last='Ferreira';   Dept='Engineering'; Title='Software Engineer';         OU='Engineering' },
    @{ First='Ben';      Last='Hartmann';   Dept='Engineering'; Title='QA Engineer';               OU='Engineering' },
    @{ First='Leila';    Last='Rashidova';  Dept='Engineering'; Title='Senior Developer';          OU='Engineering' },
    @{ First='Tom';      Last='Vickers';    Dept='Engineering'; Title='R&D Lead';                  OU='Engineering' },
    @{ First='Grace';    Last='Lindqvist';  Dept='Engineering'; Title='Systems Architect';         OU='Engineering' }
)

# ---------------------------------------------------------------------------
# SCRIPT BLOCK — runs locally on the DC
# ---------------------------------------------------------------------------
$RemoteScriptBlock = {
    param($Users, $DomainDN, $DefaultPassword)

    Import-Module ActiveDirectory -ErrorAction Stop

    $OUs = @('IT','Finance','HR','Sales','Operations','Legal',
             'Executives','ServiceAccounts','Marketing','Engineering')

    $Groups = @{
        'IT'             = 'IT-Staff'
        'Finance'        = 'Finance-Staff'
        'HR'             = 'HR-Staff'
        'Sales'          = 'Sales-Staff'
        'Operations'     = 'Ops-Staff'
        'Legal'          = 'Legal-Staff'
        'Executives'     = 'Executives'
        'ServiceAccounts'= 'ServiceAccounts'
        'Marketing'      = 'Marketing-Staff'
        'Engineering'    = 'Engineering-Staff'
    }

    $LabOUDN    = "OU=LabUsers,$DomainDN"
    $SecurePass = ConvertTo-SecureString $DefaultPassword -AsPlainText -Force

    # -----------------------------------------------------------------------
    # 1. Create top-level LabUsers OU
    # -----------------------------------------------------------------------
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$LabOUDN'" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name 'LabUsers' -Path $DomainDN -ProtectedFromAccidentalDeletion $false
        Write-Host "[+] Created OU: LabUsers" -ForegroundColor Green
    } else {
        Write-Host "[~] OU already exists: LabUsers" -ForegroundColor Yellow
    }

    # -----------------------------------------------------------------------
    # 2. Create department OUs and groups under LabUsers
    # -----------------------------------------------------------------------
    foreach ($OU in $OUs) {
        $OuDN = "OU=$OU,$LabOUDN"
        if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$OuDN'" -ErrorAction SilentlyContinue)) {
            New-ADOrganizationalUnit -Name $OU -Path $LabOUDN -ProtectedFromAccidentalDeletion $false
            Write-Host "[+] Created OU: $OU" -ForegroundColor Green
        }

        $GroupName = $Groups[$OU]
        if (-not (Get-ADGroup -Filter "Name -eq '$GroupName'" -ErrorAction SilentlyContinue)) {
            New-ADGroup -Name $GroupName `
                        -GroupScope Global `
                        -GroupCategory Security `
                        -Path $OuDN `
                        -Description "Lab group for $OU department"
            Write-Host "[+] Created Group: $GroupName" -ForegroundColor Green
        }
    }

    # -----------------------------------------------------------------------
    # 3. Create users
    # -----------------------------------------------------------------------
    $Created = 0
    $Skipped = 0

    foreach ($U in $Users) {
        $SamAccount = ($U.First + '.' + $U.Last).ToLower() -replace "[^a-z0-9.]", ""
        $SamAccount = $SamAccount.Substring(0, [Math]::Min(20, $SamAccount.Length))
        $UPN        = "$SamAccount@$($DomainDN -replace 'DC=','' -replace ',','.')"
        $TargetOU   = "OU=$($U.OU),$LabOUDN"
        $DisplayName= "$($U.First) $($U.Last)"

        if (Get-ADUser -Filter "SamAccountName -eq '$SamAccount'" -ErrorAction SilentlyContinue) {
            Write-Host "[~] Skipping existing user: $SamAccount" -ForegroundColor Yellow
            $Skipped++
            continue
        }

        $Params = @{
            SamAccountName        = $SamAccount
            UserPrincipalName     = $UPN
            GivenName             = $U.First
            Surname               = $U.Last
            DisplayName           = $DisplayName
            Name                  = $DisplayName
            Department            = $U.Dept
            Title                 = $U.Title
            Path                  = $TargetOU
            AccountPassword       = $SecurePass
            Enabled               = $true
            PasswordNeverExpires  = $true          # Convenient for lab use
            ChangePasswordAtLogon = $false
        }

        try {
            New-ADUser @Params
            Add-ADGroupMember -Identity $Groups[$U.OU] -Members $SamAccount
            Write-Host "[+] Created: $SamAccount ($($U.Title))" -ForegroundColor Cyan
            $Created++
        } catch {
            Write-Warning "[-] Failed to create $SamAccount : $_"
        }
    }

    # -----------------------------------------------------------------------
    # 4. Add special group memberships for lab attack scenarios
    # -----------------------------------------------------------------------

    # Give IT staff Remote Desktop Users membership
    foreach ($u in ($Users | Where-Object { $_.OU -eq 'IT' })) {
        $sam = ($u.First + '.' + $u.Last).ToLower() -replace "[^a-z0-9.]", ""
        try { Add-ADGroupMember -Identity 'Remote Desktop Users' -Members $sam -ErrorAction SilentlyContinue } catch {}
    }

    # Make one IT user a Domain Admin (intentional weak config for attack sim)
    try {
        Add-ADGroupMember -Identity 'Domain Admins' -Members 'marcus.ellis'
        Write-Host "[!] Added marcus.ellis to Domain Admins (intentional vuln)" -ForegroundColor Magenta
    } catch {}

    # Make service accounts members of built-in groups (Kerberoastable targets)
    try {
        Add-ADGroupMember -Identity 'Backup Operators' -Members 'svc.backup'
        Write-Host "[!] Added svc.backup to Backup Operators (intentional vuln)" -ForegroundColor Magenta
    } catch {}

    # Set SPNs on service accounts to make them Kerberoastable
    $Spns = @{
        'svc.sql'     = 'MSSQLSvc/srv01.lab.local:1433'
        'svc.web'     = 'HTTP/web01.lab.local'
        'svc.backup'  = 'BackupService/dc01.lab.local'
    }
    foreach ($svcUser in $Spns.Keys) {
        try {
            Set-ADUser -Identity $svcUser -ServicePrincipalNames @{Add=$Spns[$svcUser]}
            Write-Host "[!] Set SPN on $svcUser — Kerberoastable target" -ForegroundColor Magenta
        } catch {
            Write-Warning "Could not set SPN on $svcUser : $_"
        }
    }

    Write-Host "`n--- Summary ---" -ForegroundColor White
    Write-Host "Users Created : $Created" -ForegroundColor Green
    Write-Host "Users Skipped : $Skipped" -ForegroundColor Yellow
    Write-Host "Total in list : $($Users.Count)" -ForegroundColor White
}

# ---------------------------------------------------------------------------
# MAIN — decide connection method and invoke
# ---------------------------------------------------------------------------

# Default password for all lab users — change as needed
$DefaultPassword = 'LabPassword123!'

Write-Host "`n[*] AD Lab User Creator" -ForegroundColor White
Write-Host "[*] Target DC : $DCHostname" -ForegroundColor White
Write-Host "[*] Domain DN : $DomainDN`n"  -ForegroundColor White

if ($UseRemoting) {
    # -------------------------------------------------------------------------
    # METHOD A: PSRemoting — use when workstation is NOT domain-joined
    # Requires WinRM enabled on the DC (enabled by default on Server 2016+)
    # -------------------------------------------------------------------------
    Write-Host "[*] Connecting via PSRemoting to $DCHostname..." -ForegroundColor Cyan

    $SessionOptions = New-PSSessionOption -SkipCACheck -SkipCNCheck
    $Session = New-PSSession -ComputerName $DCHostname `
                             -Credential $Credential `
                             -SessionOption $SessionOptions `
                             -ErrorAction Stop

    Write-Host "[+] Session established.`n" -ForegroundColor Green

    try {
        Invoke-Command -Session $Session `
                       -ScriptBlock $RemoteScriptBlock `
                       -ArgumentList $UserData, $DomainDN, $DefaultPassword
    } finally {
        Remove-PSSession $Session
        Write-Host "`n[*] Session closed." -ForegroundColor Gray
    }

} else {
    # -------------------------------------------------------------------------
    # METHOD B: Local RSAT — use when workstation IS domain-joined
    # Requires: RSAT-AD-PowerShell feature installed locally
    # -------------------------------------------------------------------------
    Write-Host "[*] Using local RSAT (domain-joined mode)..." -ForegroundColor Cyan

    if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
        throw "ActiveDirectory module not found. Install RSAT: Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"
    }

    Import-Module ActiveDirectory

    # Point AD cmdlets at the target DC explicitly
    $PSDefaultParameterValues['*-AD*:Server'] = $DCHostname
    $PSDefaultParameterValues['*-AD*:Credential'] = $Credential

    & $RemoteScriptBlock $UserData $DomainDN $DefaultPassword
}

Write-Host "`n[*] Done." -ForegroundColor Green
