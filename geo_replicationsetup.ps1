
# Connect-AzureRmAccount
$SubscriptionId = 'Your subscription ID here'
# Set the resource group name and location for your primary server
#$primaryResourceGroupName = "mychristianResourceGroup-$(Get-Random)"
$primaryResourceGroupName = "Test_webapps_christian2_RG"
$primaryLocation = "usgovvirginia"
# Set the resource group name and location for your secondary server
$secondaryResourceGroupName = "DR-Test_webapps_christian2_RG"
#$secondaryResourceGroupName = "mysecondaryResourceGroup"
$secondaryLocation = "usgovtexas"
# Set an admin login and password for your servers
$adminSqlLogin = "sccadmin"
$password = "sql admin password here"
# Set server names - the logical server names have to be unique in the system
$primaryServerName = "primaryserverdb1"
$secondaryServerName = "secondaryserver"
# The sample database name
$databasename = "PrimaryDB"
# The ip address range that you want to allow to access your servers
$primaryStartIp = "173.79.10.198"
$primaryEndIp = "173.79.10.198"
$secondaryStartIp = "173.79.10.198"
$secondaryEndIp = "173.79.10.198"
$MinimalTlsVersion = "1.2"
$FailoverGroupName = "christian"


# Set subscription 
Write-host "Display our deployment subscription"
Set-AzureRmContext -SubscriptionId $subscriptionId 
# Create two new resource groups
Write-host "Create resource groups"
$primaryResourceGroup = Get-AzureRmResourceGroup -Name $primaryResourceGroupName -Location $primaryLocation 
$secondaryResourceGroup = New-AzureRmResourceGroup -Name $secondaryResourceGroupName -Location $secondaryLocation
# Create two new logical servers with a system wide unique server name
Write-host "in this case created DR logical server"
$primaryServer = Get-AzureRmSqlServer -ResourceGroupName $primaryResourceGroupName `
    -ServerName $primaryServerName `
    #-Location $primaryLocation `
    #-SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
$secondaryServer = New-AzureRmSqlServer -ResourceGroupName $secondaryResourceGroupName `
    -ServerName $secondaryServerName `
    -ServerVersion '12.0' `
    -Location $secondaryLocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
# Update Minimal TLS Version to 1.2
#$SecureString = ConvertTo-SecureString $password -AsPlainText -Force
#Set-AzureRmSqlServer -ServerName $secondaryServerName -ResourceGroupName $secondaryResourceGroupName -SqlAdministratorPassword $SecureString  -MinimalTlsVersion $MinimalTlsVersion
# Create a server firewall rule for each server that allows access from the specified IP range
$primaryserverfirewallrule = Get-AzureRmSqlServerFirewallRule -ResourceGroupName $primaryResourceGroupName `
    -ServerName $primaryservername `
    #-FirewallRuleName "AllowedIPs" -StartIpAddress $primaryStartIp -EndIpAddress $primaryEndIp
$secondaryserverfirewallrule = New-AzureRmSqlServerFirewallRule -ResourceGroupName $secondaryResourceGroupName `
    -ServerName $secondaryservername `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $secondaryStartIp -EndIpAddress $secondaryEndIp
# Allow All Windows Azure Ips (how to enable to allow all azure services)
$Allowazureservices = New-AzureRmSqlServerFirewallRule -ResourceGroupName $secondaryResourceGroupName -ServerName $secondaryservername -FirewallRuleName "AllowAllWindowsAzureIps" -StartIpAddress "0.0.0.0" -EndIpAddress "0.0.0.0" 
# Create a blank database with S0 performance level on the primary server
#$database = New-AzureRmSqlDatabase  -ResourceGroupName $primaryResourceGroupName `
    #-ServerName $primaryServerName `
    #-DatabaseName $databasename -RequestedServiceObjectiveName "S0"
# Establish Active Geo-Replication
$database = Get-AzureRmSqlDatabase -DatabaseName $databasename -ResourceGroupName $primaryResourceGroupName -ServerName $primaryServerName
$database | New-AzureRmSqlDatabaseSecondary -PartnerResourceGroupName $secondaryResourceGroupName -PartnerServerName $secondaryServerName -AllowConnections "All"


# Create a failover group between the servers
$failovergroup = Write-host "Creating a failover group between the primary and secondary server..."
New-AzureRmSqlDatabaseFailoverGroup `
   -ResourceGroupName "Test_webapps_christian2_RG" `
   -ServerName "primaryserverdb1" `
   -PartnerResourceGroupName "dr-Test_webapps_christian2_RG" `
   -PartnerServerName "secondaryserver"  `
   -FailoverGroupName "christian" `
   -FailoverPolicy Automatic `
   -GracePeriodWithDataLossHours 1 
$failovergroup


 <#Add the database to the failover group
Write-host "Adding the database to the failover group..."
Get-AzureRmSqlDatabase `
   -ResourceGroupName $primaryresourceGroupName `
   -ServerName $primaryserverName `
   -DatabaseName $databaseName | `
Add-AzureRmSqlDatabaseToFailoverGroup `
   -ResourceGroupName $primaryresourceGroupName `
   -primaryServerName "primaryserverdb1" `
   -FailoverGroupName $failoverGroupName
Write-host "Successfully added the database to the failover group..." #>



