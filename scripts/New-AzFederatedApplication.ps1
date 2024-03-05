[CmdletBinding()]
param(
    $GitHubOrgName,
    $GitHubRepoName,
    $SubscriptionName

)

$BaseName = "GitHub-$GitHubOrgName-$GitHubRepoName-To-$SubscriptionName"
$ApplicationName = "$BaseName-App"

# Create Application
New-AzADApplication -DisplayName $ApplicationName
$ClientId = (Get-AzADApplication -DisplayName $ApplicationName).AppId
New-AzADServicePrincipal -ApplicationId $ClientId

# Assign subscription role
$ObjectId = (Get-AzADServicePrincipal -DisplayName $ApplicationName).Id
$Subscription = Get-AzSubscription -SubscriptionName $SubscriptionName
$SubscriptionScope = "/subscriptions/$($Subscription.Id)"
$RoleAssignmentParameters = @{
    Objectid = $ObjectId
    RoleDefinitionName = "Contributor"
    Scope = $SubscriptionScope
}
New-AzRoleAssignment @RoleAssignmentParameters

$FederatedCredParameters = @{
    ApplicationObjectId = $ObjectId
    Audience = "api://AzureADTokenExchange"
    Issuer = "https://token.actions.githubusercontent.com/"
    Name = "$BaseName-FC"
    Subject = "repo:$GitHubOrgName/$GitHubRepoName"
}

New-AzADAppFederatedCredential @FederatedCredParameters

$AzureCredentials = @{
    subscriptionId =  (Get-AzContext).Subscription.Id
    tenantId = (Get-AzContext).Subscription.TenantId
    clientId = $ClientId   
}
Write-Output "Credentials to store in GitHub secret as AZURE_CREDENTIALS:"
Write-Output $($AzureCredentials | ConvertTo-Json)
