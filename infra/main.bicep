param location string = 'swedencentral'
param logicAppName string = 'logic-apps-fun'
param workspaceName string = 'law-logic-apps-fun'
param appInsightsName string = 'ai-logic-apps-fun'

param workflowName string = logicAppName
@description('Workflow definition JSON (object). Use @file when deploying to load from a JSON file.')
param workflowDefinition string = '{"contentVersion":"1.0.0.0","parameters":{},"actions":{},"triggers":{},"outputs":{},"$schema":"https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#"}'
@description('Workflow parameters object (optional). Use @file when deploying to load from a JSON file.')
param workflowParameters object = {}
@description('Workflow state: Enabled or Disabled')
param workflowState string = 'Enabled'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}


resource logicWorkflow 'Microsoft.Logic/workflows@2019-05-01' = {
  name: workflowName
  location: location
  tags: {}
  properties: {
    definition: json(workflowDefinition)
    parameters: workflowParameters
    state: workflowState
  }
}

resource logicDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${workflowName}-diagnostics'
  scope: logicWorkflow
  properties: {
    // send to Log Analytics workspace
    workspaceId: logAnalytics.id

    // common Logic Apps log/metric categories - enable as needed
    logs: [
      {
        category: 'WorkflowRuntime'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'ActionTracking'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'TriggerHistory'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'WorkflowEvents'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}
