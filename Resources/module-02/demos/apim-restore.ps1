Connect-AzureRmAccount

New-AzureRmApiManagement -ResourceGroupName "Pluralsight" -Name "restored-APIM-DEMO-PS-02" -Location "East US" -Organization "Zaalion" -AdminEmail "zaalion@outlook.com"

$storageKey = (Get-AzureRmStorageAccountKey -ResourceGroupName "Pluralsight" -StorageAccountName "zaalionapimstorage")[0].Value
$storageContext = New-AzureStorageContext -StorageAccountName "zaalionapimstorage" -StorageAccountKey $storageKey

Restore-AzureRmApiManagement -ResourceGroupName "Pluralsight" -Name "restored-APIM-DEMO-PS-02" -StorageContext $StorageContext -SourceContainerName "apimbackupscontainer" -SourceBlobName "apimbackupscontainer.apimdemobackup01"
