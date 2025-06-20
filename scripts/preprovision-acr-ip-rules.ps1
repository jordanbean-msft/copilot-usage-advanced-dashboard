
# Predeploy hook: Fetch public IPs for AzureContainerRegistry and update Bicep parameter file (PowerShell)

# Required environment variable (set by azd):
# AZURE_LOCATION

$Location = $env:AZURE_LOCATION

if (-not $Location) {
    Write-Error "Required environment variable AZURE_LOCATION is not set."
    exit 1
}



# Function to convert region to PascalCase with correct Azure region casing (e.g., eastus2 -> EastUS2, westeurope -> WestEurope, southeastasia -> SoutheastAsia, uksouth -> UKSouth)
function Convert-ToAzureRegionPascalCase {
    param([string]$region)
    switch -Regex ($region.ToLower()) {
        '^eastus([0-9]*)$' { return "EastUS$($Matches[1])" }
        '^westus([0-9]*)$' { return "WestUS$($Matches[1])" }
        '^centralus([0-9]*)$' { return "CentralUS$($Matches[1])" }
        '^northcentralus([0-9]*)$' { return "NorthCentralUS$($Matches[1])" }
        '^southcentralus([0-9]*)$' { return "SouthCentralUS$($Matches[1])" }
        '^westeurope$' { return "WestEurope" }
        '^northeurope$' { return "NorthEurope" }
        '^southeastasia$' { return "SoutheastAsia" }
        '^eastasia$' { return "EastAsia" }
        '^uksouth$' { return "UKSouth" }
        '^ukwest$' { return "UKWest" }
        '^francecentral$' { return "FranceCentral" }
        '^francesouth$' { return "FranceSouth" }
        '^germanywestcentral$' { return "GermanyWestCentral" }
        '^germanynorth$' { return "GermanyNorth" }
        '^norwayeast$' { return "NorwayEast" }
        '^norwaywest$' { return "NorwayWest" }
        '^switzerlandnorth$' { return "SwitzerlandNorth" }
        '^switzerlandwest$' { return "SwitzerlandWest" }
        '^uaenorth$' { return "UAENorth" }
        '^uaecentral$' { return "UAECentral" }
        '^southafricanorth$' { return "SouthAfricaNorth" }
        '^southafricawest$' { return "SouthAfricaWest" }
        '^brazilsouth$' { return "BrazilSouth" }
        '^brazilsoutheast$' { return "BrazilSoutheast" }
        '^australiaeast$' { return "AustraliaEast" }
        '^australiasoutheast$' { return "AustraliaSoutheast" }
        '^australiacentral$' { return "AustraliaCentral" }
        '^australiacentral2$' { return "AustraliaCentral2" }
        '^japaneast$' { return "JapanEast" }
        '^japanwest$' { return "JapanWest" }
        '^koreacentral$' { return "KoreaCentral" }
        '^koreasouth$' { return "KoreaSouth" }
        '^canadacentral$' { return "CanadaCentral" }
        '^canadaeast$' { return "CanadaEast" }
        '^indiacentral$' { return "IndiaCentral" }
        '^indiawest$' { return "IndiaWest" }
        '^indiasouth$' { return "IndiaSouth" }
        '^chinanorth$' { return "ChinaNorth" }
        '^chinanorth2$' { return "ChinaNorth2" }
        '^chinaeast$' { return "ChinaEast" }
        '^chinaeast2$' { return "ChinaEast2" }
        '^usgovvirginia$' { return "USGovVirginia" }
        '^usgoviowa$' { return "USGovIowa" }
        '^usgovarizona$' { return "USGovArizona" }
        '^usgovtexas$' { return "USGovTexas" }
        '^usdodeast$' { return "USDodEast" }
        '^usdodcentral$' { return "USDodCentral" }
        default { return ($region.Substring(0,1).ToUpper() + $region.Substring(1)) }
    }
}

$LocationPascal = Convert-ToAzureRegionPascalCase $Location


# Use Azure CLI to get the service tag IPs for AzureContainerRegistry in the region
# The output is a nested array, so flatten it and filter for IPv4 only
$acrIps = az network list-service-tags --location $Location --query "values[?name=='AzureContainerRegistry.$LocationPascal'].properties.addressPrefixes" -o json | ConvertFrom-Json | ForEach-Object { $_ } | ForEach-Object { $_ } | Where-Object { $_ -notmatch ":" }

if (-not $acrIps -or $acrIps.Count -eq 0) {
    Write-Error "No AzureContainerRegistry IPs found for region $Location."
    exit 1
}

# Format for Bicep parameter (array of objects with action/value)
$acrIpRules = $acrIps | ForEach-Object { @{ action = 'Allow'; value = $_ } }

# Write to a file for Bicep parameter override
$paramFile = "infra/acr-ip-rules.parameters.json"

if (Test-Path $paramFile) {
    Write-Host "Removing existing parameter file: $paramFile"
    Remove-Item $paramFile
}

# Write JSON in the same format as the bash script: { "acrNetworkRuleSetIpRules": [...] }
$json = "{`n  \"acrNetworkRuleSetIpRules\": " + ($acrIpRules | ConvertTo-Json -Depth 4) + "`n}"
Set-Content -Path $paramFile -Value $json -Encoding UTF8

Write-Host "Wrote ACR IP rules to $paramFile"
