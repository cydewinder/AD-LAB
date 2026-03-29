# Replication
-----
- We can view basic information about the last replication by using the below command.
```Powershell
PS C:\Users\Administrator>repadmin /replsummary

Replication Summary Start Time: 2026-03-29 08:09:34

Beginning data collection for replication summary, this may take awhile:
  .....


Source DSA          largest delta    fails/total %%   error
 DC1                       23m:28s    0 /   5    0
 DC2                       23m:28s    0 /   5    0


Destination DSA     largest delta    fails/total %%   error
 DC1                       23m:28s    0 /   5    0
 DC2                       23m:28s    0 /   5    0
```
- We should be able to view items that are wiaitng to be relicated using the below command.
```powershell
repadmin /queue
```
- By default replication is usually set to 180 minutes between sites. We can use the command below to force replication between sites.
```powershell
repadmin /syncall /AdeP
```
- We can also verify that replication is working properly using a test functionality
```powerhsell
dcdiag /test:replications /v
```
- We can easily find the bridgehead servers for each site using 
```powershell
repadmin /bridgeheads
```
