######################################################################################################################################################
# RemoveResourceGroupsByTag.ps1
# Copyright (c) 2018 - Microsoft Corp.
#
# Author(s): Andrew Setiawan
#
# Description:
# Powershell script to remove resources by deleting ResourceGroups based on the specified tag value and condition. 
# This script was created to help people to regularly remove unused resources to keep the bill under budget.
# Future improvements may include automatic detection on whether the resources are still being actively used or not.
#
# Parameters:
# -subscriptionId                : optional - your subscription ID (without enclosing braces). If you specify doAzureLogin switch parameter, you must specify subscriptionId parameter.
# -tagsToFind                    : optional - hash table of key value pair where you specify any tag and its value of resource group that you want to delete.
# -deleteResourceGroupWithNoTags : optional - when specified, any resource group that doesn't have tags will also be deleted. Be careful with this! It's recommended to specify simulationOnly switch first to preview the outcome.
# -doAzureLogin                  : optional - by default, the script won’t attempt to do login to your azure account. You must specify this switch if you’re opening powershell for the first time to run this script.\
# -simulationOnly                : optional - when specified, no delete operation will be done. Very useful to preview the outcome.
# -useTableFormat                : optional - when specified, this will dump the content in table (horizontal) formatting.
#
# Usage sample:
# $tagsToFind = @("DeleteMe")
# .\RemoveResourceGroupsByTag.ps1 -subscriptionId $subId -tagsToFind $tagsToFind -doAzureLogin -deleteResourceGroupWithNoTags -simulationOnly
# .\RemoveResourceGroupsByTag.ps1 -subscriptionId $subId -tagsToFind @{ keep = '1' }
#
# Notes:
# - tags are case-sensitive.
#
# History:
# 12/12/2018 - Created.
######################################################################################################################################################
<#

PS C:\> .\RemoveResourceGroupsByTag.ps1 -subscriptionId 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' -tagsToFind @{ keep = 'false' } -simulationOnly
Attempting to connect to Azure using Subscription: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ...
RemoveResourceGroupsByTag.ps1
====================================================================================================================================
Resource Groups Found:

ResourceGroupName     Location ProvisioningState Tags   TagsTable                                 ResourceId
-----------------     -------- ----------------- ----   ---------                                 ----------
XXXXXXXXX-1218-rg westus   Succeeded         {keep} ...                                       /subscriptions/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/resourceGroups/XXXXXXXXX-1218-rg
XXXXXXXXX-1217-rg westus   Succeeded                                                          /subscriptions/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/resourceGroups/XXXXXXXXX-1217-rg

Evaluating Resource Group:"XXXXXXXX-1218-rg"
tagsFromRG[keep] = false
Tag[keep] value= false matches with the specified value:false. This resource group will be deleted!
Attempting to delete Resource Group: XXXXXXXX-1218-rg ...
simulationOnly flag was specified. Not actually deleting the resource group.
Evaluating Resource Group:"XXXXXXXXX-1217-rg"
Done!


PS C:\> .\RemoveResourceGroupsByTag.ps1 -subscriptionId 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' -tagsToFind @{ keep = '0' } -simulationOnly -deleteResourceGroupWithNoTags
Attempting to connect to Azure using Subscription: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ...
RemoveResourceGroupsByTag.ps1
====================================================================================================================================
Resource Groups Found:

ResourceGroupName     Location ProvisioningState Tags   TagsTable                                 ResourceId
-----------------     -------- ----------------- ----   ---------                                 ----------
XXXXXXXXX-1218-rg westus   Succeeded         {keep} ...                                       /subscriptions/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/resourceGroups/XXXXXXXXX-1218-rg
XXXXXXXXX-1217-rg westus   Succeeded                                                          /subscriptions/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/resourceGroups/XXXXXXXXX-1217-rg

Evaluating Resource Group:"XXXXXXXX-1218-rg"
tagsFromRG[keep] = 0
Tag[keep] value= 0 matches with the specified value:0. This resource group will be deleted!
Attempting to delete Resource Group: XXXXXXXX-1218-rg ...
simulationOnly flag was specified. Not actually deleting the resource group.
Evaluating Resource Group:"XXXXXXXX-1217-rg"
Resource Group does not have tags and deleteResourceGroupWithNoTags was specified. This resource group will be deleted!
Attempting to delete Resource Group: XXXXXXXX-1217-rg ...
simulationOnly flag was specified. Not actually deleting the resource group.
Done!


PS C:\> .\RemoveResourceGroupsByTag.ps1 -subscriptionId 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' -tagsToFind @{ keep = '0' }
Attempting to connect to Azure using Subscription: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ...
RemoveResourceGroupsByTag.ps1
====================================================================================================================================
Resource Groups Found:

ResourceGroupName     Location ProvisioningState Tags   TagsTable                                 ResourceId
-----------------     -------- ----------------- ----   ---------                                 ----------
XXXXXXXXX-1218-rg westus   Succeeded         {keep} ...                                       /subscriptions/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/resourceGroups/XXXXXXXXX-1218-rg
XXXXXXXXX-1217-rg westus   Succeeded                                                          /subscriptions/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/resourceGroups/XXXXXXXXX-1217-rg

Evaluating Resource Group:"XXXXXXXX-1218-rg"
tagsFromRG[keep] = 0
Tag[keep] value= 0 matches with the specified value:0. This resource group will be deleted!
Attempting to delete Resource Group: XXXXXXXX-1218-rg ...
True
Resource group was deleted.
Evaluating Resource Group:"XXXXXXXX-1217-rg"
Done!


To Invoke this from command prompt/scheduled task:

powershell -NonInteractive -ExecutionPolicy Unrestricted -Command "c:\BIN\Scripts\RemoveResourceGroupsByTag.ps1 -deleteResourceGroupWithNoTags -tagsToFind @{ keep = '0' }"


#>

#Requires -Version 3.0
Param(
    [Parameter(Mandatory=$false)] 
    [ValidateNotNullOrEmpty()]
    [string] $subscriptionId,

    [Parameter(Mandatory=$false)] 
    [ValidateNotNullOrEmpty()]
    [hashtable] $tagsToFind = $null,

    [Parameter(Mandatory=$false)] 
    [ValidateNotNullOrEmpty()]
    [switch] $deleteResourceGroupWithNoTags = $false,

    [Parameter(Mandatory=$false)] 
    [ValidateNotNullOrEmpty()]
    [switch] $doAzureLogin = $false,

    [Parameter(Mandatory=$false)] 
    [ValidateNotNullOrEmpty()]
    [switch] $simulationOnly = $false,

    [Parameter(Mandatory=$false)] 
    [ValidateNotNullOrEmpty()]
    [switch] $useTableFormat = $false
)

Set-StrictMode -Version 3
$sep0 = '===================================================================================================================================='
Write-Host "Attempting to connect to Azure using Subscription:" $subscriptionId "..."
Write-Host 'RemoveResourceGroupsByTag.ps1' 
Write-Host $sep0 


if ($doAzureLogin.IsPresent) 
{
    Write-Host 'SubscriptionId: ' + $subscriptionId
    Connect-AzureRmAccount
    Set-AzureRmContext -SubscriptionId $subscriptionId
}


$resourceGroups = Get-AzureRmResourceGroup
Write-Host 'Resource Groups Found:'

if ($useTableFormat.IsPresent)
{
    Write-Host ($resourceGroups | Format-Table | Out-String)
}
else
{
    Write-Host ($resourceGroups | Out-String)
}

foreach ($rg in $resourceGroups)
{
    $m = 'Evaluating Resource Group:"{0}"' -f $rg.ResourceGroupName
    Write-Host $m
    $delete = $false
    $tagsFromRG = $rg.Tags
    
    if ($deleteResourceGroupWithNoTags.IsPresent -and $tagsFromRG -eq $null) 
    {
        $delete = $true
        Write-Host 'Resource Group does not have tags and deleteResourceGroupWithNoTags was specified. This resource group will be deleted!'
    }

    if ($tagsFromRG -ne $null -and $tagsToFind -ne $null)
    {
        foreach ($keyToFind in $tagsToFind.Keys)
        {
            if ($tagsFromRG.ContainsKey($keyToFind)) # Note: This is case sensitive!
            {
                $val = $tagsFromRG[$keyToFind].ToString().ToLowerInvariant() 
                $m = 'tagsFromRG[{0}] = {1}' -f $keyToFind, $val
                Write-Host $m
                $valToCompare = $tagsToFind[$keyToFind].ToString().ToLowerInvariant() 
                if ($val -eq $valToCompare)
                {
                    $m = 'Tag[{0}] value= {1} matches with the specified value:{2}. This resource group will be deleted!' -f $keyToFind, $val, $valToCompare
                    Write-Host $m
                    $delete = $true
                    break
                }
            }
        }
    }

    if ($delete)
    {
        $m = 'Attempting to delete Resource Group: {0} ...' -f $rg.ResourceGroupName
        Write-Host $m
        if ($simulationOnly.IsPresent)
        {
            Write-Host 'simulationOnly flag was specified. Not actually deleting the resource group.'
        }
        else
        {
            Remove-AzureRmResourceGroup -Id $rg.ResourceId -Force
            Write-Host 'Resource group was deleted.'
        }
    }
}

Write-Host 'Done!'

