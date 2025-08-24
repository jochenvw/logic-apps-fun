# Azure Logic Apps Fun

Azure Logic Apps Fun is a repository for experimenting with Azure Logic Apps Standard, including local development, infrastructure as code with Bicep, and deployment automation.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Bootstrap Environment
- Install required tools and dependencies:
  - `.devcontainer/init.sh` -- runs automatically in dev container, installs .NET 9 SDK and Azure CLI (~60 seconds total)
  - `npm install -g azurite` -- install Azure Storage Emulator (~30 seconds)
  - Install Azure Functions Core Tools: 
    ```bash
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
    sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
    sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/debian/11/prod bullseye main" > /etc/apt/sources.list.d/dotnetdev.list'
    sudo apt-get update && sudo apt-get install -y azure-functions-core-tools-4
    ```
    -- takes 90 seconds. NEVER CANCEL. Set timeout to 180+ seconds.

### Verify Installation
- Check tool versions:
  - `dotnet --version` -- should return 8.0.x or 9.0.x
  - `az --version` -- should return 2.76.0+
  - `func --version` -- should return 4.1.2+
  - `npm list -g azurite` -- should show azurite installed

### Local Development Workflow
1. **Start Storage Emulator (Required for Logic Apps)**:
   - `azurite --silent --location /tmp/azurite --debug /tmp/azurite/debug.log` -- runs in background (~5 seconds to start)
   - NEVER CANCEL: Storage emulator must run continuously during Logic Apps development

2. **Configure Logic Apps Project**:
   - Navigate to Logic Apps project: `cd logic-apps/simple-stateless`
   - Ensure `local.settings.json` exists with correct configuration:
     ```json
     {
       "IsEncrypted": false,
       "Values": {
         "AzureWebJobsStorage": "UseDevelopmentStorage=true",
         "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
         "WEBSITES_ENABLE_APP_SERVICE_STORAGE": "false"
       }
     }
     ```

3. **Start Logic Apps Locally**:
   - **Online Mode** (requires internet): `func start --port 7071` -- takes ~7 seconds, downloads extension bundles, may fail with network restrictions
   - **Offline Mode** (no internet): Remove `extensionBundle` section from `host.json` temporarily, then `func start --port 7071` -- takes ~7 seconds
   - NEVER CANCEL: Logic Apps runtime may take 30+ seconds to fully initialize. Set timeout to 60+ seconds.
   - Function will show "0 functions found" which is normal for empty workflows
   - **CRITICAL**: In network-restricted environments, use offline mode. Online mode requires access to cdn.functions.azure.com

### Infrastructure Deployment
- **Validate Bicep Templates**:
  - `cd infra`
  - `az login` -- required before any Azure operations
  - `az deployment group validate --resource-group [resource-group] --template-file main.bicep` -- takes ~25 seconds
  - **Deploy Infrastructure**:
    - `az deployment group create --resource-group [resource-group] --template-file main.bicep` -- takes 2-5 minutes. NEVER CANCEL. Set timeout to 600+ seconds.

### Testing and Validation
- **Always validate locally before deployment**:
  1. Start Azurite storage emulator
  2. Start Logic Apps function locally
  3. Verify function runtime starts without errors
  4. Test workflow definitions in VS Code Logic Apps designer (if using VS Code)

- **Bicep Template Validation**:
  - Always run `az deployment group validate` before actual deployment
  - Template creates Log Analytics workspace, Application Insights, and Logic Apps workflow

## Validation Scenarios

### Complete End-to-End Local Development Test
1. **Setup**: Run through complete bootstrap sequence (tools installation)
2. **Storage**: Start Azurite emulator and verify it's listening on ports 10000-10002
3. **Logic Apps**: Start Logic Apps function and verify no errors in startup logs
4. **Configuration**: Verify `host.json` and `local.settings.json` are properly configured
5. **Cleanup**: Stop Logic Apps function and Azurite when done

### Infrastructure Deployment Test
1. **Login**: `az login` with valid Azure credentials
2. **Validation**: Run Bicep template validation
3. **Deployment**: Deploy to test resource group
4. **Verification**: Verify Logic Apps workflow is created in Azure portal

## Critical Timing and Cancellation Warnings

- **NEVER CANCEL**: Azure Functions Core Tools installation takes 90 seconds - always set timeout to 180+ seconds
- **NEVER CANCEL**: Logic Apps startup can take 30+ seconds when downloading extensions - set timeout to 60+ seconds  
- **NEVER CANCEL**: Bicep deployment takes 2-5 minutes - set timeout to 600+ seconds
- **NEVER CANCEL**: Storage emulator runs continuously - only stop when completely done with Logic Apps development

## Common Issues and Solutions

### Logic Apps Won't Start
- **Extension Bundle Download Issues**: Remove `extensionBundle` section from `host.json` for offline development
- **Network Restrictions**: Error "Name or service not known (cdn.functions.azure.com:443)" indicates need for offline mode
- **Storage Connection Issues**: Ensure Azurite is running and `local.settings.json` has correct storage connection
- **Runtime Version Issues**: Use `FUNCTIONS_WORKER_RUNTIME: "dotnet-isolated"` for .NET 8+ compatibility

### Azure CLI Issues  
- **Not Logged In**: Run `az login` before any Azure operations
- **Subscription Issues**: Use `az account set --subscription [subscription-id]` to set correct subscription

### Network Restrictions
- Logic Apps extension bundles require internet access for online mode
- Use offline mode (remove extensionBundle from host.json) when network is restricted
- Bicep deployments and Azure CLI operations require internet access

## Repository Structure

### Key Directories
- `logic-apps/simple-stateless/` -- Azure Logic Apps Standard project
  - `simple-stateless/workflow.json` -- workflow definition (currently empty)
  - `host.json` -- Azure Functions host configuration with Logic Apps extension bundle
  - `local.settings.json` -- local development configuration (create if missing)
- `infra/` -- Bicep infrastructure templates
  - `main.bicep` -- main deployment template for Logic Apps resources
  - `main.azcli.template` -- example Azure CLI deployment commands
- `.devcontainer/` -- development container configuration
  - `init.sh` -- automated setup script for .NET SDK and Azure CLI
  - `devcontainer.json` -- VS Code dev container configuration
- `.vscode/` -- VS Code workspace settings for Logic Apps development

### Key Files Reference
```
.
├── .devcontainer/
│   ├── devcontainer.json    # VS Code dev container config
│   └── init.sh             # Setup script (.NET SDK, Azure CLI)
├── .vscode/
│   ├── settings.json       # Logic Apps VS Code settings
│   └── mcp.json           # VS Code configuration
├── infra/
│   ├── main.bicep         # Infrastructure as code template
│   └── main.azcli.template # Example deployment commands
├── logic-apps/
│   ├── simple-stateless/
│   │   ├── host.json      # Azure Functions host config
│   │   ├── local.settings.json # Local development settings
│   │   └── simple-stateless/
│   │       └── workflow.json # Logic Apps workflow definition
│   └── logic-apps.code-workspace # VS Code workspace
└── logic-apps-fun.code-workspace # Root workspace file
```

## Frequently Used Commands Reference

### Environment Setup
```bash
# Install Azure Functions Core Tools (90 seconds)
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/debian/11/prod bullseye main" > /etc/apt/sources.list.d/dotnetdev.list'
sudo apt-get update && sudo apt-get install -y azure-functions-core-tools-4

# Install Azurite globally (30 seconds)
npm install -g azurite
```

### Local Development
```bash
# Start storage emulator (background)
azurite --silent --location /tmp/azurite --debug /tmp/azurite/debug.log

# Start Logic Apps (foreground)
cd logic-apps/simple-stateless
func start --port 7071

# Verify tools
dotnet --version  # Should be 8.0+ or 9.0+
az --version      # Should be 2.76.0+
func --version    # Should be 4.1.2+
```

### Azure Deployment
```bash
# Login and validate
az login
cd infra
az deployment group validate --resource-group [rg-name] --template-file main.bicep

# Deploy (2-5 minutes)
az deployment group create --resource-group [rg-name] --template-file main.bicep
```

Always run local validation before making any code changes. Always test the complete local development workflow after any changes to configuration files.