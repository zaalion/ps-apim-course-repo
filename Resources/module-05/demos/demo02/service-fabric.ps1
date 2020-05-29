
Connect-ServiceFabricCluster -ConnectionEndpoint apim-fabric-zaa-01.eastus.cloudapp.azure.com:19000 `
    -KeepAliveIntervalInSec 10 `
    -X509Credential -ServerCertThumbprint  `
    -FindType FindByThumbprint -FindValue  `
    -StoreLocation CurrentUser -StoreName My


# Check that you are connected and the cluster is healthy
Get-ServiceFabricClusterHealth

<#
$bytes = [System.IO.File]::ReadAllBytes("[PATN TO THE PFX FILE]\apim-fab-vault-zaalioncert01-20181112.pfx");
$b64 = [System.Convert]::ToBase64String($bytes);
[System.Io.File]::WriteAllText("c:\apim-fab-vault-zaalioncert01-20181112.txt", $b64);
#>

clear

$groupname = "APIMFAB01"
$clusterloc="eastus"
$templatepath="[THE PATH TO THE TEMPLATES FOLDER]"

New-AzureRmResourceGroupDeployment -ResourceGroupName $groupname `
-TemplateFile "$templatepath\network-apim.json" `
-TemplateParameterFile "$templatepath\network-apim.parameters.json" -Verbose

New-AzureRmResourceGroupDeployment -ResourceGroupName $groupname -TemplateFile "$templatepath\apim.json" `
-TemplateParameterFile "$templatepath\apim.parameters.json" -Verbose