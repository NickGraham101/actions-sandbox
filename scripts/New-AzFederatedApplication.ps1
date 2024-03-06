[CmdletBinding()]
param(
    # Name of the Github organisation that contains the repo
    [Parameter(Mandatory=$true)]
    [string]$GitHubOrgName,
    # Name of the GitHub repo that will be able to make changes to the subscription
    [Parameter(Mandatory=$true)]
    [string]$GitHubRepoName,
    # Name of the Azure subscription that the repo will have Contributor rights over.  An identically named Environment needs to be created in the GitHub repo.
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionName
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
$FederatedCredParameters = @{
    ApplicationObjectId = $ApplicationObjectId
    Audience = "api://AzureADTokenExchange"
    Issuer = "https://token.actions.githubusercontent.com"
    Name = "$BaseName-FC"
    Subject = "repo:$GitHubOrgName/$GitHubRepoName`:environment:$SubscriptionName"
}
if (!$FederatedCredential) {
    New-AzADAppFederatedCredential @FederatedCredParameters
}
elseif ($FederatedCredential.Subject -ne $FederatedCredParameters["Subject"]) {
    $FederatedCredParameters.Remove("Name")
    $FederatedCredParameters["FederatedCredentialId"] = $FederatedCredential.Id
    Update-AzADAppFederatedCredential @FederatedCredParameters
}

Write-Output "Credentials to store in GitHub secrets"
Write-Output "AZURE_SUBSCRIPTION_ID :  $((Get-AzContext).Subscription.Id)"
Write-Output "AZURE_TENANT_ID : $((Get-AzContext).Subscription.TenantId)"
Write-Output "AZURE_CLIENT_ID : $ApplicationClientId"
