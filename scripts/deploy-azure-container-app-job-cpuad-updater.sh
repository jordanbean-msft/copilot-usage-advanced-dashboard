#!/bin/bash

set -e

# Check if 'azd' command is available
if ! command -v azd &> /dev/null; then
    echo "Error: 'azd' command is not found. Please ensure you have 'azd' installed."
    echo "For installation instructions, visit: https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd"
    exit 1
fi

# Check if 'az' command is available
if ! command -v az &> /dev/null; then
    echo "Error: 'az' command is not found. Please ensure you have 'az' installed."
    echo "For installation instructions, visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

echo ""
echo "Loading azd .env file from current environment"
echo ""

# Load environment variables from azd
while IFS='=' read -r key value; do
    if [[ $key && $value ]]; then
        export "$key"="${value%\"}"
        export "$key"="${value#\"}"
    fi
done < <(azd env get-values)

if [[ $? -ne 0 ]]; then
    echo "Failed to load environment variables from azd environment"
    exit 1
else
    echo "Successfully loaded env vars from .env file."
fi

# Check if resources are provisioned
if [[ "${AZD_IS_PROVISIONED,,}" != "true" ]]; then
    echo "Azure resources are not provisioned. Please run 'azd provision' to set up the necessary resources before running this script."
    exit 1
fi

# Set variables
resourceGroup="$AZURE_RESOURCE_GROUP_NAME"
environment="$AZURE_CONTAINER_APPS_ENVIRONMENT_NAME"
jobName="$AZURE_RESOURCE_CPUAD_UPDATER_NAME"
loginServer="$AZURE_CONTAINER_REGISTRY_ENDPOINT"
tag="azd-$(date +'%Y%m%d%H%M%S')"
image="$AZURE_CONTAINER_REGISTRY_ENDPOINT/copilot-usage-advanced-dashboard/cpuad-updater-job:$tag"
projectDir="$(realpath "$(dirname "$0")/../src/cpuad-updater")"

# Display variables
echo "Resource Group: $resourceGroup"
echo "Environment: $environment"
echo "Job Name: $jobName"
echo "Login Server: $loginServer"
echo "Image: $image"
echo "Project Directory: $projectDir"

# Build and push Docker image
echo "Starting ACR Task to build and push Docker image..."
az acr build --registry "$loginServer" --image "copilot-usage-advanced-dashboard/cpuad-updater-job:$tag" --file "$projectDir/Dockerfile" "$projectDir"
if [[ $? -ne 0 ]]; then
    echo "ACR Task failed"
    exit 1
fi
echo "ACR Task succeeded"

# Update Azure Container App Job
echo "Updating Azure Container App Job..."
az containerapp job update --name "$jobName" --resource-group "$resourceGroup" --image "$image"
if [[ $? -ne 0 ]]; then
    echo "Container App Job update failed"
    exit 1
fi
echo "Container App Job update succeeded"

# Success message
echo "Deployed Azure Container App Job successfully"

echo "Starting Azure Container App Job..."
az containerapp job start --name "$jobName" --resource-group "$resourceGroup"
if [ $? -ne 0 ]; then
    echo "Container App Job start failed"
    exit 1
fi

echo "Container App Job started successfully"

# Azure Portal URL
portalUrl="https://portal.azure.com/#@$AZURE_TENANT_ID/resource$AZURE_CONTAINER_APP_JOB_URL"
echo "You can view the Container App Job in the Azure Portal: $portalUrl"