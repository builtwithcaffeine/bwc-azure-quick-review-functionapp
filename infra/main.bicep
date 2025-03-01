targetScope = 'subscription'

@description('User Account GUID')
param userAccountGuid string

@description('Azure Location')
param location string

@description('Azure Location Short Code')
param locationShortCode string

@description('Environment Type')
@allowed([
  'dev'
  'acc'
  'prod'
])
param environmentType string

@description('Customer Name')
param customerName string

@description('User Deployment Name')
param deployedBy string

@description('Azure Metadata Tags')
param tags object = {
  product: 'Azure Quick Review'
  environmentType: environmentType
  deployedBy: deployedBy
  deployedDate: utcNow('yyyy-MM-dd')
}

@description('Enable Email Notifications')
@allowed([
  true
  false
])
param emailEnabled bool

@description('Configure SMTP Server Address')
param emailSMTPServer string

@description('Configure SMTP Server Port')
@allowed([
  25
  587
  465
])
param emailSMTPPort int

@description('Configure SMTP Server Username')
@secure()
param emailSMTPAuthUserName string

@description('Configure SMTP Server Password')
@secure()
param emailSMTPAuthPassword string

@description('Configure Email Sender')
param emailSender string

@description('Configure Email Recipient')
param emailRecipient string

//
// Resource Names
//

@description('Resource Group Name')
var resourceGroupName = 'rg-${customerName}-aqr-${environmentType}-${locationShortCode}'

@description('Managed Identity Name')
var userManagedIdentityName = 'id-${customerName}-aqr-${environmentType}-${locationShortCode}'

@description('Storage Account Name')
var storageAccountName = 'st${customerName}aqr${environmentType}${locationShortCode}'

@description('Key Vault Name')
var keyvaultName = 'kv-${customerName}-aqr-${environmentType}-${locationShortCode}'

@description('Application Insights Name')
var appInsightsName = 'appi-${customerName}-aqr-${environmentType}-${locationShortCode}'

@description('Log Analytics Name')
var logAnalyticsName = 'log-${customerName}-aqr-${environmentType}-${locationShortCode}'

@description('App Service Plan Name')
var appServicePlanName = 'asp-${customerName}-aqr-${environmentType}-${locationShortCode}'

@description('Function App Name')
var funcAppName = 'func-${customerName}-aqr-${environmentType}-${locationShortCode}'

//
// Resource Configuration
//

//
// Key Vault Variables
//

@allowed([
  'standard'
  'premium'
])
@description('Key Vault SKU')
param kvSku string = 'standard'

@allowed([
  true
  false
])
@description('Key Vault Purge Protection')
param kvPurgeProtection bool = false

@allowed([
  true
  false
])
@description('Key Vault RBAC Authorization')
param kvRbacAuthorization bool = true

@description('Key Vault Soft Delete')
param kvSoftDeleteRetentionInDays int = 7

@description('Key Vault Network ACLs')
param kvNetworkAcls object = {
  bypass: 'AzureServices'
  defaultAction: 'Allow'
}

@description('Key Vault Secrets')
param kvSecretArray array = [
  {
    name: 'emailSMTPAuthUserName'
    value: empty(emailSMTPAuthUserName) ? 'place-holder' : emailSMTPAuthUserName
  }
  {
    name: 'emailSMTPAuthPassword'
    value: empty(emailSMTPAuthPassword) ? 'place-holder' : emailSMTPAuthPassword
  }
]

// Storage Account Variables
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
])
@description('Storage Account SKU Name')
param stSkuName string = 'Standard_LRS'

@allowed([
  'TLS1_2'
  'TLS1_3'
])
@description('Storage Account TLS Version')
param stTlsVersion string = 'TLS1_2'

@allowed([
  'Enabled'
  'Disabled'
])
@description('Storage Account Public Network Access')
param stPublicNetworkAccess string = 'Enabled'

@allowed([
  true
  false
])
@description('Storage Account Allowed Shared Key Access')
param stAllowedSharedKeyAccess bool = true

@description('Storage Account Network ACLs')
param stNetworkAcls object = {
  bypass: 'AzureServices'
  defaultAction: 'Allow'
}

//
// Log Analytics Variables
//

@description('Log Analytics Data Retention')
param logAnalyticsDataRetention int = 30

//
// App Service Plan Variables
//

@description('App Service Plan Capacity')
param aspCapacity int = 1

@description('App Service Plan SKU Name')
param aspSkuName string = 'Y1'

@description('App Service Plan Kind')
param aspKind string = 'linux'

//
// Azure Function Variables
//

@allowed([
  'functionapp' // function app windows os
  'functionapp,linux' // function app linux os
  'functionapp,workflowapp' // logic app workflow
  'functionapp,workflowapp,linux' // logic app docker container
  'functionapp,linux,container' // function app linux container
  'functionapp,linux,container,azurecontainerapps' // function app linux container azure container apps
  'app,linux' // linux web app
  'app' // windows web app
  'linux,api' // linux api app
  'api' // windows api app
  'app,linux,container' // linux container app
  'app,container,windows' // windows container app
])
@description('Function App Kind')
param funcAppKind string = 'functionapp,linux'

@allowed([
  true
  false
])
@description('Function App System Assigned Identity')
param funcAppSystemAssignedIdentity bool = false

@description('Function App Package Url')
param funcAppPackageUrl string = 'https://raw.githubusercontent.com/smoonlee/sandbox/refs/heads/main/latest.zip'

@description('Function App Settings Key Value Pairs')
var funcAppSettingsKeyValuePairs = {
  APPLICATIONINSIGHTS_CONNECTION_STRING: createApplicationInsights.outputs.connectionString
  WEBSITE_RUN_FROM_PACKAGE: funcAppPackageUrl
  WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: '@Microsoft.KeyVault(VaultName=${keyvaultName};SecretName=connectionString1)'
  WEBSITE_CONTENTSHARE: funcAppName
  FUNCTIONS_EXTENSION_VERSION: '~4'
  FUNCTIONS_WORKER_RUNTIME: 'powershell'
  managedIdentityId: createUserManagedIdentity.outputs.clientId
  emailEnabled: emailEnabled
  emailRecipient: emailRecipient
  emailSender: emailSender
  emailSMTPServer: emailSMTPServer
  emailSMTPPort: emailSMTPPort
  emailSMTPAuthUserName: '@Microsoft.KeyVault(VaultName=${keyvaultName};SecretName=emailSMTPAuthUserName)'
  emailSMTPAuthPassword: '@Microsoft.KeyVault(VaultName=${keyvaultName};SecretName=emailSMTPAuthPassword)'
}

@description('Function App Site Configuration')
var funcAppSiteConfig = {
  alwaysOn: false
  linuxFxVersion: 'POWERSHELL|7.4'
  ftpsState: 'Disabled'
  http20Enabled: true
  minTlsVersion: '1.3'
  use32BitWorkerProcess: false
  cors: {
    allowedOrigins: [
      'https://portal.azure.com'
    ]
  }
}

@description('Function App Basic Publishing Credentials Policies')
var funcAppBasicPublishingCredentialsPolicies = [
  {
    allow: false
    name: 'ftp'
  }
  {
    allow: true
    name: 'scm'
  }
]

@description('Function App Log Configuration')
var funcAppLogConfiguration = {
  applicationLogs: {
    fileSystem: {
      level: 'Verbose'
    }
  }
  detailedErrorMessages: {
    enabled: true
  }
  failedRequestsTracing: {
    enabled: true
  }
  httpLogs: {
    fileSystem: {
      enabled: true
      retentionInDays: 1
      retentionInMb: 35
    }
  }
}

//
// NO HARD CODING UNDER THERE! K THANKS BYE 👋
//

// [AVM Module] - Resource Group
module createResourceGroup 'br/public:avm/res/resources/resource-group:0.4.1' = {
  name: 'create-resource-group'
  params: {
    name: resourceGroupName
    location: location
    tags: tags
  }
}

module createCustomRole 'modules/authorization/role-definition/main.bicep' = {
  name: 'create-azure-quick-review-rbac-role'
  params: {
    name: 'Azure Quick Review Reader'
    roleName: 'Azure Quick Review Reader'
    description: 'Custom RBAC for Azure Quick Review Audit'
    location: location
    actions: [
      '*/read'
      'Microsoft.CostManagement/*/read'
    ]
    assignableScopes: [
      '/subscriptions/${subscription().subscriptionId}'
    ]
  }
  dependsOn: [
    createResourceGroup
  ]
}

// [AVM Module] - User Managed Identity
module createUserManagedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  name: 'create-userManaged-identity'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: userManagedIdentityName
    location: location
    tags: tags
  }
  dependsOn: [
    createResourceGroup
  ]
}

// [AVM] - PTN - Role Assignment
// https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/authorization/role-assignment
module RoleAssignment 'modules/authorization/role-assignments/subscription.bicep' = {
  name: 'roleAssignmentDeployment'
  scope: subscription()
  params: {
    principalId: createUserManagedIdentity.outputs.principalId
    roleDefinitionIdOrName: createCustomRole.outputs.roleDefinitionIdName
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    createCustomRole
    createUserManagedIdentity
  ]
}

// [AVM] - Key Vault
module createKeyVault 'br/public:avm/res/key-vault/vault:0.12.1' = {
  name: 'create-key-vault'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: keyvaultName
    sku: kvSku
    location: location
    tags: tags
    enableRbacAuthorization: kvRbacAuthorization
    enablePurgeProtection: kvPurgeProtection
    softDeleteRetentionInDays: kvSoftDeleteRetentionInDays
    networkAcls: kvNetworkAcls
    roleAssignments: [
      {
        principalId: createUserManagedIdentity.outputs.principalId
        roleDefinitionIdOrName: 'Key Vault Secrets Officer'
        principalType: 'ServicePrincipal'
      }
      {
        principalId: userAccountGuid
        roleDefinitionIdOrName: 'Key Vault Secrets Officer'
        principalType: 'User'
      }
    ]
    secrets: kvSecretArray
  }
  dependsOn: [
    createUserManagedIdentity
  ]
}

// [AVM Module] - Storage Account
module createStorageAccount 'br/public:avm/res/storage/storage-account:0.18.1' = {
  name: 'create-storage-account'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: storageAccountName
    location: location
    skuName: stSkuName
    minimumTlsVersion: stTlsVersion
    publicNetworkAccess: stPublicNetworkAccess
    allowSharedKeyAccess: stAllowedSharedKeyAccess
    secretsExportConfiguration: {
      accessKey1Name: 'accessKey1'
      accessKey2Name: 'accessKey2'
      connectionString1Name: 'connectionString1'
      connectionString2Name: 'connectionString2'
      keyVaultResourceId: createKeyVault.outputs.resourceId
    }
    networkAcls: stNetworkAcls
    tags: tags
  }
  dependsOn: [
    createKeyVault
  ]
}

// [AVM Module] - Log Analytics
module createLogAnalytics 'br/public:avm/res/operational-insights/workspace:0.11.1' = {
  name: 'create-log-analytics'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: logAnalyticsName
    location: location
    dataRetention: logAnalyticsDataRetention
    tags: tags
  }
  dependsOn: [
    createResourceGroup
  ]
}

// [AVM Module] - Application Insights
module createApplicationInsights 'br/public:avm/res/insights/component:0.6.0' = {
  name: 'create-app-insights'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: appInsightsName
    workspaceResourceId: createLogAnalytics.outputs.resourceId
    location: location
    tags: tags
  }
  dependsOn: [
    createResourceGroup
  ]
}

// [AVM Module] - App Service Plan
module createAppServicePlan 'br/public:avm/res/web/serverfarm:0.4.1' = {
  scope: resourceGroup(resourceGroupName)
  name: 'create-app-service-plan'
  params: {
    name: appServicePlanName
    skuCapacity: aspCapacity
    skuName: aspSkuName
    kind: aspKind
    location: location
    tags: tags
  }
  dependsOn: [
    createResourceGroup
  ]
}

// [AVM Module] - Function App
module createfuncApp 'br/public:avm/res/web/site:0.15.0' = {
  name: 'create-function-app'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: funcAppName
    location: location
    kind: funcAppKind
    httpsOnly: true
    serverFarmResourceId: createAppServicePlan.outputs.resourceId
    appInsightResourceId: createApplicationInsights.outputs.resourceId
    keyVaultAccessIdentityResourceId: createUserManagedIdentity.outputs.resourceId
    storageAccountRequired: true
    storageAccountResourceId: createStorageAccount.outputs.resourceId
    managedIdentities: {
      systemAssigned: funcAppSystemAssignedIdentity
      userAssignedResourceIds: [
        createUserManagedIdentity.outputs.resourceId
      ]
    }
    appSettingsKeyValuePairs: funcAppSettingsKeyValuePairs
    siteConfig: funcAppSiteConfig
    basicPublishingCredentialsPolicies: funcAppBasicPublishingCredentialsPolicies
    logsConfiguration: funcAppLogConfiguration
    tags: tags
  }
  dependsOn: [
    createUserManagedIdentity
    createAppServicePlan
  ]
}
