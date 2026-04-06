targetScope = 'resourceGroup'

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Prefix used for resource names')
param namePrefix string = 'dreamflow'

@description('App Service SKU for API app')
param appServiceSkuName string = 'F1'

@description('Linux runtime stack for API app')
param linuxFxVersion string = 'NODE|20-lts'

@description('Deploy App Service plan and API web app (disable if subscription has zero App Service quota)')
param deployApiWebApp bool = false

@description('Redis SKU name')
@allowed([
  'Basic'
  'Standard'
])
param redisSkuName string = 'Basic'

@description('Redis capacity')
param redisCapacity int = 0

resource appInsights 'microsoft.insights/components@2020-02-02' = {
  name: '${namePrefix}-appi'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    IngestionMode: 'ApplicationInsights'
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = if (deployApiWebApp) {
  name: '${namePrefix}-plan'
  location: location
  sku: {
    name: appServiceSkuName
    tier: appServiceSkuName == 'F1' ? 'Free' : 'Basic'
    size: appServiceSkuName
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource apiWebApp 'Microsoft.Web/sites@2023-12-01' = if (deployApiWebApp) {
  name: '${namePrefix}-api'
  location: location
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      appSettings: [
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'REDIS_HOST'
          value: '${redis.name}.redis.cache.windows.net'
        }
        {
          name: 'REDIS_PORT'
          value: '6380'
        }
      ]
      alwaysOn: appServiceSkuName == 'F1' ? false : true
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      http20Enabled: true
    }
  }
}

resource redis 'Microsoft.Cache/Redis@2024-03-01' = {
  name: '${namePrefix}-redis'
  location: location
  properties: {
    sku: {
      name: redisSkuName
      family: 'C'
      capacity: redisCapacity
    }
    minimumTlsVersion: '1.2'
    redisVersion: '6'
    enableNonSslPort: false
    publicNetworkAccess: 'Enabled'
  }
}

output apiUrl string = deployApiWebApp ? 'https://${apiWebApp!.properties.defaultHostName}' : 'not-deployed'
output redisHost string = '${redis.name}.redis.cache.windows.net'
