$rg = (new-azurermresourcegroup -name Contoso-IaaS -Location westus2).ResourceGroupName
$rg2 = (new-azurermresourcegroup -name Contoso-PaaS -Location westus2).ResourceGroupName
$outputs = (new-azurermresourcegroupdeployment -Name infraSecLab -ResourceGroupName $rg -TemplateUri https://raw.githubusercontent.com/dcant6/Security/master/azuredeploy/azuredeploy.json).Outputs

$DestStorageAccount = $outputs.storageAccountName.Value
$SourceStorageAccount = "infraseclab"
$destStorageKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $rg -accountName $DestStorageAccount).value[0]
$sasToken = "?sv=2019-10-10&ss=bfqt&srt=c&sp=rwdlacupx&se=2020-05-09T17:16:58Z&st=2020-05-09T09:16:58Z&sip=120.159.40.147&spr=https&sig=T6RwBAigaR6ms6honTgsMoUH4KjqtycTrJ4JEF30wZA%3D"
$SourceStorageContext = New-AzureStorageContext –StorageAccountName $SourceStorageAccount -SasToken $sasToken
$DestStorageContext = New-AzureStorageContext –StorageAccountName $DestStorageAccount -StorageAccountKey $DestStorageKey
$SourceStorageContainer = 'infraseclab'
$DestStorageContainer = (new-azurestoragecontainer -Name contoso -permission Container -context $DestStorageContext).name

$Blobs = (Get-AzureStorageBlob -Context $SourceStorageContext -Container $SourceStorageContainer)
foreach ($Blob in $Blobs)
{
   Write-Output "Moving $Blob.Name"
   Start-CopyAzureStorageBlob -Context $SourceStorageContext -SrcContainer $SourceStorageContainer -SrcBlob $Blob.Name `
      -DestContext $DestStorageContext -DestContainer $DestStorageContainer -DestBlob $Blob.Name
}

Write-Output "***** IaaS Lab Ready :-) *****"
new-azurermresourcegroupdeployment -Name infraSecpaasLab -ResourceGroupName $rg2 -TemplateUri https://raw.githubusercontent.com/dcant6/Security/master/azuredeploy/azuredeploy-paas.json
Write-Output "***** PaaS Lab Ready :-) *****"
