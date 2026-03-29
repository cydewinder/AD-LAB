# Lab Configuration
______
## Domain
- lab.local
## Workstations
- pfsense firewall
	- lan (corp_net) : 10.10.100.1
	- opt1 (operations_net) : 10.10.200.1
	- currently no restrictions between the networks.
- dc1 : 10.10.10.105
	- corp_net : 10.10.100.10
	- handling dhcp
	- configured 8.8.8.8 and 1.1.1.1 as dns forwarders
- dc2 : secondary domain controller
	- ops_net
	- handling dhcp
	- configured 8.8.8.8 and 1.1.1.1 as dns forwarders
- file1 : network file server (HR share and Operations share)
	- corp_net
- wk1 : workstation 1
	- corp_net
- wk2 : workstation 2
	- ops_net
- kali : attacking machine
	- corp_net