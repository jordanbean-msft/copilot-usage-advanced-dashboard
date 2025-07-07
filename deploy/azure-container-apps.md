

## Architecture diagram

![](/image/architecture.drawio.png)

## Technology stack

Dependent technology stack:

- Azure Container Apps
- Elasticsearch
- Grafana
- Python3


## Deploy in Azure Container Apps
This document describes how to deploy the application in Azure Container Apps using the Azure Developer CLI.

1. Run the following command to set the GitHub credentials in the Azure Developer CLI.

   ```shell
   azd env set GITHUB_PAT ...

   azd env set GITHUB_ORGANIZATION_SLUGS ...
   ```

   - `GITHUB_PAT`:
      - Your GitHub account needs to have Owner permissions for Organizations.
      - [Create a personal access token (classic)](https://docs.github.com/en/enterprise-cloud@latest/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-personal-access-token-classic) of your account with the `manage_billing:copilot`, `read:enterprise`, `read:org` scope. Then please replace `<YOUR_GITHUB_PAT>` with the actual PAT.
      - If you encounter PAT permission error, please **Allow access via fine-grained personal access tokens** in Organization's **Settings** - **Personal access tokens**.
   - `GITHUB_ORGANIZATION_SLUGS`: The Slugs of all Organizations that you want to monitor, which can be one or multiple separated by `,` (English symbol). **If you are using Copilot Standalone, use your Standalone Slug here, prefixed with `standalone:`, for example `standalone:YOUR_STANDALONE_SLUG`**. Please replace `<YOUR_ORGANIZATION_SLUGS>` with the actual value. For example, the following types of values are supported:
      - `myOrg1`
      - `myOrg1,myOrg2`
      - `standalone:myStandaloneSlug`
      - `myOrg1,standalone:myStandaloneSlug`

1. **Optional** Run the following commands to set the Grafana credentials. Note that not setting this values results in the deployment script generating credentials.

   ```shell
   azd env set GRAFANA_USERNAME ...

   azd env set GRAFANA_PASSWORD ...
   ```

1. Run the following command to deploy the application.

   ```shell
   azd up
   ```

1. After the deployment is complete, you can access the application using the URL provided in the output.

1. The username & password for the Grafana dashboard can be found in the Key Vault. Note that the default values (if you didn't specify them or are not using Entra ID auth) are not secure credentials and should be changed.

### Optional: Enable Entra ID SSO for Grafana

The Grafana dashboard only uses the `Viewer` role. This means all users that can sign in can see the same data. If you need more fine-grained access, you should follow this URL to set up Entra ID SSO for Grafana: [Grafana Entra ID SSO](https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/configure-authentication/azuread/). You can also limit which users can sign in to the Grafana dashboard using [Entra ID groups](https://learn.microsoft.com/en-us/entra/identity-platform/howto-restrict-your-app-to-a-set-of-users)

1. Create an app registration in Entra ID (Azure Active Directory) with the following settings:

   - **Name**: `copilot-usage-advanced-dashboard` (or something similar)
   - **Supported account types**: Accounts in this organizational directory only (Single tenant)
   - **Redirect URI**: Leave this blank for now, you can update it after the deployment.
   - **Overview->Application (client) ID**: Copy this value, you will need it later.
   - **Overview->Directory (tenant) ID**: Copy this value, you will need it later.
   - **Authentication->Implicit grant and hybrid flows**: Check the box for `ID tokens` to enable OpenID Connect authentication.
   - **API permissions**: Add the following delegated API permissions to allow Container Apps to sign-in users.
     - Microsoft Graph
       - `openid`
       - `profile`
       - `offline_access`
       - `User.Read`

1. Run the following command to set the Entra ID tenant ID

   ```shell
   azd env set AZURE_AUTHENTICATION_ENABLED true

   azd env set AZURE_AUTHENTICATION_CLIENT_ID <your-app-registration-client-id>

   azd env set AZURE_AUTHENTICATION_OPEN_ID_ISSUER https://login.microsoftonline.com/<your-tenant-id>
   ```

1. Run the following command to deploy the application.

   ```shell
   azd up
   ```

1. **Optional**: If you enabled Entra ID authentication, you will need to update the Entra ID app registration with values from the deployment.

   - **Authentication->Redirect URI**: Update the app registration with the URL of the Grafana dashboard, e.g., `https://<your-container-app-name>.<location>.azurecontainerapps.io/.auth/login/aad/callback`.
   - **Certificates & secrets->Federated credentials**: Add a new federated credential with the following settings:
     - **Federated credential scenario**: Managed Identity
     - **Select managed identity**: Select the managed identity created for the Container App (look in the Azure portal under the Container App's Identity section to find the name of the managed identity).
     - **Name**: `copilot-usage-advanced-dashboard` (or something similar)

1. After the deployment is complete, you can access the application using the URL provided in the output.

### Optional: Enable private networking

**Note**: This deployment assumes you already have a virtual network set up in Azure and that you have automation in place to create all necessary DNS records for the private endpoints. The deployment will not create the virtual network or DNS records for you.

Your virtual network should have the following configuration:
- Size: At least `/22` for the main address space.
- Subnets:
   - A subnet for the Container Apps, which is used to host the application.
     - At least `/23` is recommended for the Container Apps subnet.
     - Delegate the subnet to `Microsoft.App/environment`.
   - A subnet for the private endpoints for all Azure PaaS services. At least `/27` is recommended for the private endpoint subnet.

1. Private networking support can be enabled by setting the following environment variables:

   ```shell
   azd env set AZURE_VIRTUAL_NETWORK_PROVISION_PRIVATE_ENDPOINTS true

   azd env set AZURE_VIRTUAL_NETWORK_PUBLIC_NETWORK_ACCESS Disabled

   azd env set AZURE_VIRTUAL_NETWORK_NAME <your-vnet-name>

   azd env set AZURE_VIRTUAL_NETWORK_RESOURCE_GROUP_NAME <your-vnet-resource-group-name>

   azd env set AZURE_VIRTUAL_NETWORK_ADDRESS_PREFIXES <your-vnet-address-prefixes>

   azd env set AZURE_VIRTUAL_NETWORK_CONTAINER_APPS_SUBNET_NAME <your-container-apps-subnet-name>

   azd env set AZURE_VIRTUAL_NETWORK_CONTAINER_APPS_SUBNET_ADDRESS_PREFIX <your-container-apps-subnet-address-prefix>

   azd env set AZURE_VIRTUAL_NETWORK_CONTAINER_APPS_SUBNET_NSG_NAME <your-container-apps-subnet-nsg-name>

   azd env set AZURE_VIRTUAL_NETWORK_PRIVATE_ENDPOINT_SUBNET_NAME <your-private-endpoint-subnet-name>

   azd env set AZURE_VIRTUAL_NETWORK_PRIVATE_ENDPOINT_SUBNET_ADDRESS_PREFIX <your-private-endpoint-subnet-address-prefix>

   azd env set AZURE_VIRTUAL_NETWORK_PRIVATE_ENDPOINT_SUBNET_NSG_NAME <your-private-endpoint-subnet-nsg-name>
   ```

1. Run the following command to deploy the application.

   ```shell
   azd up
   ```
