Connect-AzureRmAccount

New-AzureRmStorageAccount -StorageAccountName "zaalionapimstorage" -Location 'East US' -ResourceGroupName "Pluralsight" -Type Standard_LRS
$storageKey = (Get-AzureRmStorageAccountKey -ResourceGroupName "Pluralsight" -StorageAccountName "zaalionapimstorage")[0].Value
$storageContext = New-AzureStorageContext -StorageAccountName "zaalionapimstorage" -StorageAccountKey $storageKey
New-AzureStorageContainer -Name "apimbackupscontainer" -Permission Off -Context $storageContext

Backup-AzureRmApiManagement -ResourceGroupName "Pluralsight" -Name "APIM-DEMO-PS-02" -StorageContext $StorageContext -TargetContainerName "apimbackupscontainer" -TargetBlobName "apimbackupscontainer.apimdemobackup01"