## Prerequesites ##

### Storage Account ###

Normal v2 storage account to use the table store. Create a table called status.

Store the connection string in an automation variable called ConnectionString. Select encrypted for this variable.

### Automation Account ###

Install the following modules from the gallery Az.Accounts, Az.Resources, Az.Storage, Az.Compute, Az.DesktopVirtualization, AzTable

Ensure that the resources and storage module are fully installed before attempting to install AzTable otherwise it fails. 

Import all the runbooks. 

Add an automation variable called Delay - type Int - and set it to a value in hours between the initial drain time and when you want to start alerting users. Select encrypted for this variable. 

### Initial Table Population ###

Run PopulateTable runbook. Parameters are hostpoolname and resourcegroupname - run once for each hostpool.

This will add each session host to the storage table and give it a status of "New". Further processes will then alter and read the status of each machine.

The partitition key is set to the host pool name with each row key representing one session host.

### Set Drain Mode ###

Run the DrainSession runbook. Parameters are hostpoolname and resourcegroupname and percentage.

Enables a percentage of hosts to be put into drain mode and updates the table status for each to "Draining".

### Azure Key Vault ###

Enable a webhook on the WVDActions runbook - store the webhook address as a key vault secret. 

### Logic App ###

Create a new logic app and enabled managed identity. Give the MI Get,List secret permissions on the key vault

Add a recurrence trigger with 10 minute timer

Add a Get Secret activity and use the managed identity to retrieve the KV secret.

Add a HTTP request activity and do a POST. Set the uri to the "value" from the Get Secret activity

Add a body as below:

```
{
        "HostPoolName": "",
        "ResourceGroupName": ""
}
```

### Drain Remaining Sessions ###

When the initial reboot sequence is complete (delay + 1 hr max) - run this runbook to put any machines still with a status of new into drain mode.

The WVDActions runbook running on the timer will then follow the same process (start after delay etc) to reboot the remaining machines.
