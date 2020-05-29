################################################################################################
#####  See the main article here:
#####  https://docs.microsoft.com/en-us/azure/api-management/api-management-howto-integrate-internal-vnet-appgateway
################################################################################################

Login-AzureRmAccount

# Create a Virtual Network and a subnet for the application gateway

$resGroupName = "apim-appGw-PS01" # resource group name
$location = "East US"           # Azure region
New-AzureRmResourceGroup -Name $resGroupName -Location $location

# to be used for Application Gateway while creating a Virtual Network
$appgatewaysubnet = New-AzureRmVirtualNetworkSubnetConfig -Name "apim001" -AddressPrefix "10.0.0.0/24"

# to be used for API Management while creating a Virtual Network.
$apimsubnet = New-AzureRmVirtualNetworkSubnetConfig -Name "apim002" -AddressPrefix "10.0.1.0/24"

# Create a Virtual Network
$vnet = New-AzureRmVirtualNetwork -Name "appgwvnet" -ResourceGroupName $resGroupName -Location $location `
-AddressPrefix "10.0.0.0/16" -Subnet $appgatewaysubnet,$apimsubnet

# Assign a subnet variable for the next steps
$appgatewaysubnetdata = $vnet.Subnets[0]
$apimsubnetdata = $vnet.Subnets[1]


# Create an API Management service inside a VNET configured in internal mode

#Create an API Management Virtual Network object using the subnet $apimsubnetdata
$apimVirtualNetwork = New-AzureRmApiManagementVirtualNetwork -Location $location -SubnetResourceId $apimsubnetdata.Id

# Create an API Management service inside the Virtual Network.
$apimServiceName = "ZaalionPSApi001"       # API Management service instance name
$apimOrganization = "Zaalion"          # organization name
$apimAdminEmail = "zaalion@outlook.com" # administrator's email address
$apimService = New-AzureRmApiManagement -ResourceGroupName $resGroupName -Location $location `
-Name $apimServiceName -Organization $apimOrganization -AdminEmail $apimAdminEmail `
-VirtualNetwork $apimVirtualNetwork -VpnType "Internal" -Sku "Developer"

#
#10.0.1.5 ZaalionPSApi001.azure-api.net
#10.0.1.5 ZaalionPSApi001.portal.azure-api.net
#10.0.1.5 ZaalionPSApi001.management.azure-api.net
#10.0.1.5 ZaalionPSApi001.scm.azure-api.net
#

# Create a public IP address for the front-end configuration
$publicip = New-AzureRmPublicIpAddress -ResourceGroupName $resGroupName -name "publicIP001" `
-location $location -AllocationMethod Dynamic

############# create certificates
# makecert -n "CN=api.zaalion.com" -r -sv zaaperkmeCA.pvk zaaperkmeCA.cer
# C:\Program Files (x86)\Windows Kits\10\bin\10.0.17763.0\x64\
# pvk2pfx.exe -pvk C:\zaaapiperkmeCA.pvk -spc C:\zaaapiperkmeCA.cer -pfx C:\zaaapiperkmeCA.pfx -pi [YOUR-CERTIFICATE-PASSWORD] -f

# makecert -n "CN=portal.zaalion.com" -r -sv zaaporperkmeCA.pvk zaaporperkmeCA.cer
# C:\Program Files (x86)\Windows Kits\10\bin\10.0.17763.0\x64\
# pvk2pfx.exe -pvk C:\zaaporperkmeCA.pvk -spc C:\zaaporperkmeCA.cer -pfx C:\zaaporperkmeCA.pfx -pi [YOUR-CERTIFICATE-PASSWORD] -f

# Set-up a custom domain name in API Management

# Upload the certificates with private keys for the domains
$gatewayHostname = "api.zaalion.com"                 # API gateway host
$portalHostname = "portal.zaalion.com"               # API developer portal host
$gatewayCertCerPath = "C:\Users\Reza\Google Drive\0-Pluralsight\2-Api-Management\Resources\module-05\demo\ssl\zaaapiperkmeCA.cer" # full path to api.contoso.net .cer file
$gatewayCertPfxPath = "C:\Users\Reza\Google Drive\0-Pluralsight\2-Api-Management\Resources\module-05\demo\ssl\zaaapiperkmeCA.pfx" # full path to api.contoso.net .pfx file
$portalCertPfxPath = "C:\Users\Reza\Google Drive\0-Pluralsight\2-Api-Management\Resources\module-05\demo\ssl\zaaporperkmeCA.pfx"   # full path to portal.contoso.net .pfx file
$gatewayCertPfxPassword = "[YOUR-CERTIFICATE-PASSWORD]"   # password for api.contoso.net pfx certificate
$portalCertPfxPassword = "[YOUR-CERTIFICATE-PASSWORD]"    # password for portal.contoso.net pfx certificate
$certUploadResult = Import-AzureRmApiManagementHostnameCertificate -ResourceGroupName $resGroupName `
-Name $apimServiceName -HostnameType "Proxy" -PfxPath $gatewayCertPfxPath -PfxPassword $gatewayCertPfxPassword -PassThru
$certPortalUploadResult = Import-AzureRmApiManagementHostnameCertificate -ResourceGroupName $resGroupName `
-Name $apimServiceName -HostnameType "Proxy" -PfxPath $portalCertPfxPath -PfxPassword $portalCertPfxPassword -PassThru

# Once the certificates are uploaded, create hostname configuration objects for the proxy and for the portal.
$proxyHostnameConfig = New-AzureRmApiManagementHostnameConfiguration `
-CertificateThumbprint $certUploadResult.Thumbprint -Hostname $gatewayHostname
$portalHostnameConfig = New-AzureRmApiManagementHostnameConfiguration `
-CertificateThumbprint $certPortalUploadResult.Thumbprint -Hostname $portalHostname
$result = Set-AzureRmApiManagementHostnames -Name $apimServiceName -ResourceGroupName $resGroupName `
–PortalHostnameConfiguration $portalHostnameConfig -ProxyHostnameConfiguration $proxyHostnameConfig


# Create application gateway configuration

# reate an application gateway IP configuration named gatewayIP001
$gipconfig = New-AzureRmApplicationGatewayIPConfiguration -Name "gatewayIP001" -Subnet $appgatewaysubnetdata

# Configure the front-end IP port for the public IP endpoint. This port is the port that end users connect to.
$fp01 = New-AzureRmApplicationGatewayFrontendPort -Name "port001"  -Port 443

# Configure the front-end IP with public IP endpoint.
$fipconfig01 = New-AzureRmApplicationGatewayFrontendIPConfig -Name "frontend1" -PublicIPAddress $publicip


# Configure the certificates for the Application Gateway, which will be used to decrypt and re-encrypt the traffic passing through.

$certPwd = ConvertTo-SecureString $gatewayCertPfxPassword -AsPlainText -Force
$cert = New-AzureRmApplicationGatewaySslCertificate -Name "cert01" -CertificateFile $gatewayCertPfxPath `
-Password $certPwd
$certPortalPwd = ConvertTo-SecureString $portalCertPfxPassword -AsPlainText -Force
$certPortal = New-AzureRmApplicationGatewaySslCertificate -Name "cert02" -CertificateFile $portalCertPfxPath `
-Password $certPortalPwd


# Create the HTTP listeners for the Application Gateway. Assign the front-end IP configuration, port, and ssl certificates to them.
$listener = New-AzureRmApplicationGatewayHttpListener -Name "listener01" -Protocol "Https" `
-FrontendIPConfiguration $fipconfig01 -FrontendPort $fp01 -SslCertificate $cert -HostName $gatewayHostname `
-RequireServerNameIndication true
$portalListener = New-AzureRmApplicationGatewayHttpListener -Name "listener02" -Protocol "Https" `
-FrontendIPConfiguration $fipconfig01 -FrontendPort $fp01 -SslCertificate $certPortal -HostName $portalHostname `
-RequireServerNameIndication true

# Create custom probes to the API Management service
$apimprobe = New-AzureRmApplicationGatewayProbeConfig -Name "apimproxyprobe" -Protocol "Https" `
-HostName $gatewayHostname -Path "/status-0123456789abcdef" -Interval 30 -Timeout 120 -UnhealthyThreshold 8
$apimPortalProbe = New-AzureRmApplicationGatewayProbeConfig -Name "apimportalprobe" -Protocol "Https" `
-HostName $portalHostname -Path "/signin" -Interval 60 -Timeout 300 -UnhealthyThreshold 8

# Upload the certificate to be used on the SSL-enabled backend pool resources.
$authcert = New-AzureRmApplicationGatewayAuthenticationCertificate -Name "whitelistcert1" -CertificateFile $gatewayCertCerPath

# Configure HTTP backend settings for the Application Gateway. This includes setting a time-out limit for backend request, after which they're canceled. This value is different from the probe time-out.
$apimPoolSetting = New-AzureRmApplicationGatewayBackendHttpSettings -Name "apimPoolSetting" -Port 443 `
-Protocol "Https" -CookieBasedAffinity "Disabled" -Probe $apimprobe -AuthenticationCertificates $authcert -RequestTimeout 180
$apimPoolPortalSetting = New-AzureRmApplicationGatewayBackendHttpSettings -Name "apimPoolPortalSetting" `
-Port 443 -Protocol "Https" -CookieBasedAffinity "Disabled" -Probe $apimPortalProbe `
-AuthenticationCertificates $authcert -RequestTimeout 180

# Configure a back-end IP address pool named apimbackend with the internal virtual IP address of the API Management service created above.
$apimProxyBackendPool = New-AzureRmApplicationGatewayBackendAddressPool -Name "apimbackend" `
-BackendIPAddresses $apimService.StaticIPs[1]

# Create rules for the Application Gateway to use basic routing.
$rule01 = New-AzureRmApplicationGatewayRequestRoutingRule -Name "rule1" -RuleType Basic -HttpListener $listener `
-BackendAddressPool $apimProxyBackendPool -BackendHttpSettings $apimPoolSetting
$rule02 = New-AzureRmApplicationGatewayRequestRoutingRule -Name "rule2" -RuleType Basic -HttpListener $portalListener `
-BackendAddressPool $apimProxyBackendPool -BackendHttpSettings $apimPoolPortalSetting

# Configure the number of instances and size for the Application Gateway. In this example, we are using the WAF SKU for increased security of the API Management resource.
$sku = New-AzureRmApplicationGatewaySku -Name "WAF_Medium" -Tier "WAF" -Capacity 2

# Configure WAF to be in "Prevention" mode.
$config = New-AzureRmApplicationGatewayWebApplicationFirewallConfiguration -Enabled $true -FirewallMode "Prevention"

# Create an Application Gateway with all the configuration objects from the preceding steps.
$appgwName = "apim-app-gw001"
$appgw = New-AzureRmApplicationGateway -Name $appgwName -ResourceGroupName $resGroupName -Location $location `
-BackendAddressPools $apimProxyBackendPool -BackendHttpSettingsCollection $apimPoolSetting, $apimPoolPortalSetting `
-FrontendIpConfigurations $fipconfig01 -GatewayIpConfigurations $gipconfig -FrontendPorts $fp01 `
-HttpListeners $listener, $portalListener `
-RequestRoutingRules $rule01, $rule02 -Sku $sku -WebApplicationFirewallConfig $config -SslCertificates $cert, $certPortal `
-AuthenticationCertificates $authcert -Probes $apimprobe, $apimPortalProbe 


# CNAME the API Management proxy hostname to the public DNS name of the Application Gateway resource

Get-AzureRmPublicIpAddress -ResourceGroupName $resGroupName -Name "publicIP001"
# >>>> 35d1149c-2417-41c9-8f70-2a533c18f1ee.cloudapp.net