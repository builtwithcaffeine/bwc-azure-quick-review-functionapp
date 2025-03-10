
function Update-ApiPermissions {

param (
    [string] $MSIName
)

# Import Modules
$graphModules = ('Microsoft.Graph.Authentication','Microsoft.Graph.Applications')
forEach ($module in $graphModules) { Import-Module -Name $module}

# Log in as a user with the "Privileged Role Administrator" role
Connect-MgGraph -NoWelcome -TenantId $tenantId -Scopes "AppRoleAssignment.ReadWrite.All,Application.Read.All"

$tenantId = (Get-AzContext).Tenant.Id      # Your tenant ID

# Search for Microsoft Graph
$MSGraphSP = Get-MgServicePrincipal -Filter "DisplayName eq 'Microsoft Graph'";

$MSI = Get-MgServicePrincipal -Filter "DisplayName eq '$MSIName'"
if ($MSI.Count -gt 1) {
    Write-Output "More than 1 principal found with that name, please find your principal and copy its object ID. Replace the above line with the syntax $MSI = Get-MgServicePrincipal -ServicePrincipalId <your_object_id>"
    Exit
}

# Get required permissions
$Permissions = @(
    "Organization.Read.All"
)

# Find app permissions within Microsoft Graph application
$MSGraphAppRoles = $MSGraphSP.AppRoles | Where-Object { ($_.Value -in $Permissions) }

# Assign the managed identity app roles for each permission
foreach ($AppRole in $MSGraphAppRoles) {
    $AppRoleAssignment = @{
        principalId = $MSI.Id
        resourceId  = $MSGraphSP.Id
        appRoleId   = $AppRole.Id
    }

    New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $AppRoleAssignment.PrincipalId -BodyParameter $AppRoleAssignment -Verbose
}
}