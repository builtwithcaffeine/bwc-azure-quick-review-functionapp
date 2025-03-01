# Azure Functions profile.ps1
#
# This script runs during a "cold start" of your Function App.
# A "cold start" happens when:
#
# * The Function App starts for the first time.
# * The Function App starts after being de-allocated due to inactivity.
#
# You can use this file to define helper functions, run commands, or set environment variables.
# NOTE: Any non-environment variables will be reset after the first execution.

# Authenticate with Azure PowerShell using Managed Identity (MSI) if Managed Identity ID is available.
if ($env:managedIdentityId) {

    # Disable automatic Az context saving for the current process to avoid conflicts.
    Disable-AzContextAutosave -Scope Process | Out-Null

    # Authenticate to Azure using Managed Identity.
    Write-Host "Authenticating with Azure using Managed Identity..."
    Connect-AzAccount -Identity -AccountId $env:managedIdentityId | Out-Null

    # Retrieve the Azure access token for Microsoft Graph API.
    $azAccessToken = (Get-AzAccessToken -AsSecureString -ResourceUrl "https://graph.microsoft.com").Token

    # Connect to Microsoft Graph using the access token.
    Write-Host "Authenticating with Microsoft Graph..."
    Connect-MgGraph -AccessToken $azAccessToken | Out-Null

    Write-Host "Authentication successful."
}
else {
    Write-Warning "Managed Identity ID is not found. Azure authentication will be skipped."
}
