[CmdletBinding()]
param(
    $GitHubOrgName,
    $GitHubRepoName,
    $SubscriptionName

)

$BaseName = "GitHub-$GitHubOrgName-$GitHubRepoName-To-$SubscriptionName"
$ApplicationName = "$BaseName-App"

# Get \ Create Application
$Application = Get-AzADApplication -DisplayName $ApplicationName -ErrorAction SilentlyContinue
if (!$Application) {
    New-AzADApplication -DisplayName $ApplicationName
    New-AzADServicePrincipal -ApplicationId $ApplicationClientId
}
$Application = Get-AzADApplication -DisplayName $ApplicationName
$ApplicationClientId = $Application.AppId
$ApplicationObjectId = $Application.Id

# Assign subscription role
$SpnObjectId = (Get-AzADServicePrincipal -DisplayName $ApplicationName).Id
$Subscription = Get-AzSubscription -SubscriptionName $SubscriptionName
$SubscriptionScope = "/subscriptions/$($Subscription.Id)"
$RoleAssignmentParameters = @{
    Objectid = $SpnObjectId
    RoleDefinitionName = "Contributor"
    Scope = $SubscriptionScope
}
$RoleAssignment = Get-AzRoleAssignment @RoleAssignmentParameters
if (!$RoleAssignment) {
    New-AzRoleAssignment @RoleAssignmentParameters
}

$FederatedCredential = Get-AzADAppFederatedCredential -ApplicationObjectId $ApplicationObjectId
if (!$FederatedCredential) {
    $FederatedCredParameters = @{
        ApplicationObjectId = $ApplicationObjectId
        Audience = "api://AzureADTokenExchange"
        Issuer = "https://token.actions.githubusercontent.com/"
        Name = "$BaseName-FC"
        Subject = "repo:$GitHubOrgName/$GitHubRepoName"
    }
    New-AzADAppFederatedCredential @FederatedCredParameters
}

$AzureCredentials = @{
    subscriptionId =  (Get-AzContext).Subscription.Id
    tenantId = (Get-AzContext).Subscription.TenantId
    clientId = $ApplicationClientId   
}
Write-Output "Credentials to store in GitHub secret as AZURE_CREDENTIALS:"
Write-Output $($AzureCredentials | ConvertTo-Json)
