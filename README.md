
Automation 1 - Run this on Friday night
1) Put 70% of vms into drain mode
   Get 70% of hosts, write them to storage so we can do the remaining later
   Update-AzWvdSessionHost -AllowNewSession $false

Automation 2 - Start running ~6 hours after automation 1

2) Foreach $host
        if session = 0 then reboot (need to save reboot state as well)
        else
        Send-AzWvdUserSessionMessage and update the state

HostName,status
host01,(Normal,Draining,30,20,10,Rebooting,Complete)
..
