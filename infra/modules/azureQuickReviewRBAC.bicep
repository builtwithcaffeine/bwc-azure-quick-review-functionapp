param subscriptionId string

resource customRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: 'Azure Quick Review Reader Role'
  properties: {
    roleName: 'Azure Quick Review Reader Role'
    description: 'Custom role combining Reader and Cost Management Reader permissions for Azure Quick Review.'
    actions: [
      '*/read'
      'Microsoft.CostManagement/*/read'
    ]
    notActions: []
    assignableScopes: [
      '/subscriptions/${subscriptionId}'
    ]
  }
}
