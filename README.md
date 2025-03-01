# Azure Quick Review - Function App

[Azure Quick Review](https://github.com/azure/azqr) is a PowerShell-based tool designed to automate the review of Azure environments by gathering key security, configuration, and compliance insights. It helps Azure administrators and security teams quickly assess their cloud posture by checking various Azure resources against best practices and recommendations.

## Key Features
- **Security & Compliance Checks** – Evaluates Azure resources against security best practices.
- **Resource Inventory** – Collects metadata on Azure resources across subscriptions.
- **Performance & Cost Insights** – Identifies potential optimizations.
- **Automated Report Generation** – Outputs findings in JSON, CSV, or Markdown format.
- **Integration with Azure DevOps & Automation** – Can be scheduled via pipelines or Azure Functions.

## Use Cases
- Periodic security and compliance reviews.
- Auditing Azure configurations.
- Automating governance in DevOps workflows.

# Infrastructure As Code

```
.\Invoke-AzDeployment.ps1 -targetscope sub -subscriptionId b67e1026-b589-41e2-b41f-73f8803f71a0 -customerName bwcaz -environmentType acc -location westeurope -deploy
```