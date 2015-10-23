<# Modifying to check-in
.SYNOPSIS
    Connects to Azure and starts of all VMs in the specified Azure subscription

.DESCRIPTION
   This runbook sample demonstrates how to connect to Azure using organization id credential
   based authentication. Before using this runbook, you must create an Azure Active Directory
   user and allow that user to manage the Azure subscription you want to work against. You must
   also place this user's username / password in an Azure Automation credential asset.
   
   You can find more information on configuring Azure so that Azure Automation can manage your
   Azure subscription(s) here: http://aka.ms/Sspv1l

   After configuring Azure and creating the Azure Automation credential asset, make sure to
   update this runbook to contain your Azure subscription name and credential asset name.

   This runbook can be scheduled to start all VMs at a certain time of day.  When creating schedule assets,
   use every 7 days as the interval to create a scheduled start for each desired work day.  i.e. Every Monday at 7am, 

.NOTES
	Original Author: System Center Automation Team
    Last Updated: 10/02/2014  -   Microsoft Services - Adapted to start all VMs.
                  03/10/2015  -   Microsoft Services - removed unecessary inlinescript and started in parallel
                  03/30/2015  -   Microsoft Services - added 1 minute retry interval for 5 minutes
#>

workflow First-Runbook
{   
	# Add the credential used to authenticate to Azure. 
	# TODO: Fill in the -Name parameter with the Name of the Automation PSCredential asset
	# that has access to your Azure subscription.  "myPScredName" is your asset name that reflects an OrgID user
    # like "someuser@somewhere.onmicrosoft.com" that has Co-Admin rights to your subscription.
	$Cred = Get-AutomationPSCredential -Name "myPScredName"

	# Connect to Azure
	Add-AzureAccount -Credential $Cred

	# Select the Azure subscription you want to work against
	# TODO: Fill in the -SubscriptionName parameter with the name of your Azure subscription
	Select-AzureSubscription -SubscriptionName "Some Subscription Name"

    # TODO: Set a String Variable in Assets named FirstServer to the name of the server you want to start first.
    $firstServer = Get-AutomationVariable -Name 'FirstServer'

	# start your DC or other server first
    $startFirst = Get-AzureVM | where-object -FilterScript{$_.name -eq $firstServer -and $_.status -like 'Stopped*' }
    if($startFirst)
       {
         $startFirst|Start-AzureVM
         sleep 60
       }

     # Get remaining VMs that are stopped and Start everything all at once
     $VMs = Get-AzureVM | where-object -FilterScript{$_.status -like 'Stopped*' } 
    
     foreach -parallel ($vm in $VMs)
       {       
         
        $startRtn = Start-AzureVM -Name $VM.Name -ServiceName $VM.ServiceName -ea SilentlyContinue
        $count=1
        if(($startRtn.OperationStatus) -ne 'Succeeded')
          {
           do{
              Write-Output "Failed to start $($VM.Name). Retrying in 60 seconds..."
              sleep 60
              $startRtn = Start-AzureVM -Name $VM.Name -ServiceName $VM.ServiceName  -ea SilentlyContinue
              $count++
              }
            while(($startRtn.OperationStatus) -ne 'Succeeded' -and $count -lt 5)
         
           }
           
        if($startRtn){Write-Output "Start-AzureVM cmdlet for $($VM.Name) $($startRtn.OperationStatus) on attempt number $count of 5."}
             
  
       }
      
}