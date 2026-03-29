# LDAP
------
- We can query ldap using the "adsisearcher" type accelerator in PowerShell. (https://devblogs.microsoft.com/scripting/use-the-powershell-adsisearcher-type-accelerator-to-search-active-directory/)
```powershell
PS C:\> $a = [adsisearcher]“objectcategory=user”  
PS C:\> $a.FindAll()

Path                                                                  Properties
----                                                                  ----------
LDAP://CN=Administrator,CN=Users,DC=lab,DC=local                      {logoncount, codepage, objectcategory, descrip...
LDAP://CN=Guest,CN=Users,DC=lab,DC=local                              {logoncount, codepage, objectcategory, descrip...
LDAP://CN=krbtgt,CN=Users,DC=lab,DC=local                             {logoncount, codepage, objectcategory, descrip...
LDAP://CN=James Holloway,OU=IT,OU=LabUsers,DC=lab,DC=local            {givenname, codepage, objectcategory, departme...
```
- We can also filter these results down more using the filter keyword.
```powershell
PS C:\Users\Administrator> $a.Filter = "name=Ben Hartmann"
PS C:\Users\Administrator> $a.FindAll()

Path                                                              Properties
----                                                              ----------
LDAP://CN=Ben Hartmann,OU=Engineering,OU=LabUsers,DC=lab,DC=local {givenname, codepage, objectcategory, department...}
```
- We can use this same filtering concept to find user accounts that have SPNs attached.
```powershell
PS C:\Users\Administrator> $searcher = [ADSISearcher]"(&(objectCategory=user)(servicePrincipalName=*))"
PS C:\Users\Administrator> $searcher.FindAll()

Path                                                                Properties
----                                                                ----------
LDAP://CN=krbtgt,CN=Users,DC=lab,DC=local                           {logoncount, codepage, objectcategory, descripti...
LDAP://CN=svc backup,OU=ServiceAccounts,OU=LabUsers,DC=lab,DC=local {givenname, codepage, objectcategory, department...
LDAP://CN=svc sql,OU=ServiceAccounts,OU=LabUsers,DC=lab,DC=local    {givenname, codepage, objectcategory, department...
LDAP://CN=svc web,OU=ServiceAccounts,OU=LabUsers,DC=lab,DC=local    {givenname, codepage, objectcategory, department...


PS C:\Users\Administrator>
```
- We can also put the search filter into a variable and then call that variable as shown below.
```powershell
PS C:\Users\Administrator> $filter = "(&(objectClass=user)(adminCount=1))"
PS C:\Users\Administrator> $a = [ADSISearcher]$filter
PS C:\Users\Administrator> $a.FindAll()

Path                                                                Properties
----                                                                ----------
LDAP://CN=Administrator,CN=Users,DC=lab,DC=local                    {logoncount, codepage, objectcategory, descripti...
LDAP://CN=krbtgt,CN=Users,DC=lab,DC=local                           {logoncount, codepage, objectcategory, descripti...
LDAP://CN=Marcus Ellis,OU=IT,OU=LabUsers,DC=lab,DC=local            {givenname, codepage, objectcategory, department...
LDAP://CN=svc backup,OU=ServiceAccounts,OU=LabUsers,DC=lab,DC=local {givenname, codepage, objectcategory, department...
```
- We can also query the AD Schema using PowerShell as shown below.
```powershell
PS C:\Users\Administrator>
>> $schemaPath = "CN=Schema,CN=Configuration,$((Get-ADRootDSE).defaultNamingContext)"
>> Get-ADObject -SearchBase $schemaPath -Filter {objectClass -eq "classSchema"} -Properties *


adminDescription                : Organization
adminDisplayName                : Organization
CanonicalName                   : lab.local/Configuration/Schema/Organization
CN                              : Organization
Created                         : 11/10/2017 11:25:45 AM
createTimeStamp                 : 11/10/2017 11:25:45 AM
defaultHidingValue              : False
defaultObjectCategory           : CN=Organization,CN=Schema,CN=Configuration,DC=lab,DC=local
defaultSecurityDescriptor       : D:(A;;RPWPCRCCDCLCLORCWOWDSDDTSW;;;DA)(A;;RPWPCRCCDCLCLORCWOWDSDDTSW;;;SY)(A;;RPLCLOR
                                  C;;;AU)
Deleted                         :
Description                     :
DisplayName                     :
DistinguishedName               : CN=Organization,CN=Schema,CN=Configuration,DC=lab,DC=local
dSCorePropagationData           : {12/31/1600 4:00:00 PM}
governsID                       : 2.5.6.4
instanceType                    : 4
isDeleted                       :
LastKnownParent                 :
lDAPDisplayName                 : organization
Modified                        : 11/10/2017 11:25:45 AM
modifyTimeStamp                 : 11/10/2017 11:25:45 AM
Name                            : Organization
```