#!/bin/bash
# Predeploy hook: Fetch public IPs for AzureContainerRegistry and update Bicep parameter file

set -e

# Required environment variables (set by azd):
# AZURE_LOCATION

if [[ -z "$AZURE_LOCATION" ]]; then
  echo "Required environment variables AZURE_LOCATION are not set."
  exit 1
fi


# Function to convert region to PascalCase with correct Azure region casing (e.g., eastus2 -> EastUS2, westeurope -> WestEurope, southeastasia -> SoutheastAsia, uksouth -> UKSouth)
to_pascal_case() {
  local region="$1"
  # Handle common Azure region abbreviations
  region=$(echo "$region" | sed -E 's/^eastus([0-9]*)$/EastUS\1/i; s/^westus([0-9]*)$/WestUS\1/i; s/^centralus([0-9]*)$/CentralUS\1/i; s/^northcentralus([0-9]*)$/NorthCentralUS\1/i; s/^southcentralus([0-9]*)$/SouthCentralUS\1/i; s/^westeurope$/WestEurope/i; s/^northeurope$/NorthEurope/i; s/^southeastasia$/SoutheastAsia/i; s/^eastasia$/EastAsia/i; s/^uksouth$/UKSouth/i; s/^ukwest$/UKWest/i; s/^francecentral$/FranceCentral/i; s/^francesouth$/FranceSouth/i; s/^germanywestcentral$/GermanyWestCentral/i; s/^germanynorth$/GermanyNorth/i; s/^norwayeast$/NorwayEast/i; s/^norwaywest$/NorwayWest/i; s/^switzerlandnorth$/SwitzerlandNorth/i; s/^switzerlandwest$/SwitzerlandWest/i; s/^uaenorth$/UAENorth/i; s/^uaecentral$/UAECentral/i; s/^southafricanorth$/SouthAfricaNorth/i; s/^southafricawest$/SouthAfricaWest/i; s/^brazilsouth$/BrazilSouth/i; s/^brazilsoutheast$/BrazilSoutheast/i; s/^australiaeast$/AustraliaEast/i; s/^australiasoutheast$/AustraliaSoutheast/i; s/^australiacentral$/AustraliaCentral/i; s/^australiacentral2$/AustraliaCentral2/i; s/^japaneast$/JapanEast/i; s/^japanwest$/JapanWest/i; s/^koreacentral$/KoreaCentral/i; s/^koreasouth$/KoreaSouth/i; s/^canadacentral$/CanadaCentral/i; s/^canadaeast$/CanadaEast/i; s/^indiacentral$/IndiaCentral/i; s/^indiawest$/IndiaWest/i; s/^indiasouth$/IndiaSouth/i; s/^chinanorth$/ChinaNorth/i; s/^chinanorth2$/ChinaNorth2/i; s/^chinaeast$/ChinaEast/i; s/^chinaeast2$/ChinaEast2/i; s/^usgovvirginia$/USGovVirginia/i; s/^usgoviowa$/USGovIowa/i; s/^usgovarizona$/USGovArizona/i; s/^usgovtexas$/USGovTexas/i; s/^usdodeast$/USDodEast/i; s/^usdodcentral$/USDodCentral/i;')
  echo "$region"
}

ACR_LOCATION_PASCAL=$(to_pascal_case "$AZURE_LOCATION")

# Use Azure CLI to get the service tag IPs for AzureContainerRegistry in the region
# The output is a nested array, so flatten it and filter for IPv4 only
ACR_IPS=$(az network list-service-tags --location "$AZURE_LOCATION" --query "values[?name=='AzureContainerRegistry.$ACR_LOCATION_PASCAL'].properties.addressPrefixes" -o json | jq -r '.[][]' | grep -v ':')

if [[ -z "$ACR_IPS" ]]; then
  echo "No AzureContainerRegistry IPs found for region $AZURE_LOCATION."
  exit 1
fi

# Format for Bicep parameter (array of objects with action/value)
ACR_IP_RULES=$(echo "$ACR_IPS" | jq -R '{action: "Allow", value: .}' | jq -s .)

# Write to a file for Bicep parameter override
PARAM_FILE="infra/acr-ip-rules.parameters.json"

if [[ -f "$PARAM_FILE" ]]; then
  echo "Removing existing parameter file: $PARAM_FILE"
  rm "$PARAM_FILE"
fi

echo -e "{\n  \"acrNetworkRuleSetIpRules\": $ACR_IP_RULES\n}" > "$PARAM_FILE"

echo "Wrote ACR IP rules to $PARAM_FILE"
