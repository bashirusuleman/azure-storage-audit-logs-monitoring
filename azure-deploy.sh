#!/bin/bash

# Variables
RESOURCE_GROUP=""
STORAGE_ACCOUNT=""
EVENT_HUB_NAMESPACE=""
EVENT_HUB_NAME=""
EVENT_HUB_RG=""
REGION="eastus"
STORAGEADITLOGS=""

RESOURCE_EXISTS=$(az storage group show --name "$RESOURCE_GROUP" --query "id" --output tsv 2>/dev/null)

if [[ -z "$RESOURCE_EXISTS" ]]; then
    echo "Not Creating Resource group: Resource group'$RESOURCE_GROUP' exist"
    # exit 1
else 
  
    echo "Creating resource group"

        az group create \
        --name $RESOURCE_GROUP \
        --location $REGION

fi

az eventhubs namespace create \
    --name $EVENT_HUB_NAMESPACE \
    --resource-group $RESOURCE_GROUP \
    --location $REGION


az eventhubs eventhub create \
    --name $EVENT_HUB_NAME \
    --resource-group $RESOURCE_GROUP \
    --namespace-name $EVENT_HUB_NAMESPACE


echo "Fetching Event Hub Authorization Rule ID..."
EVENT_HUB_AUTH_RULE_ID=$(az eventhubs namespace authorization-rule show \
    --resource-group "$EVENT_HUB_RG" \
    --namespace-name "$EVENT_HUB_NAMESPACE" \
    --name "RootManageSharedAccessKey" \
    --query "id" --output tsv 2>/dev/null)

echo "Check if Event Hub Authorization Rule ID is retrieved"
if [[ -z "$EVENT_HUB_AUTH_RULE_ID" ]]; then
    echo "Error: Failed to retrieve Event Hub Authorization Rule ID."
    exit 1
fi

echo "Checking if Storage Account exists..."
STORAGE_EXISTS=$(az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" --query "id" --output tsv 2>/dev/null)

if [[ -z "$STORAGE_EXISTS" ]]; then
    echo "Creating Storage Account '$STORAGE_ACCOUNT'  in resource group '$RESOURCE_GROUP'."

     az storage account create  \
        --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" \
        --location eastus  \
        --sku Standard_LRS
 
fi

echo "Enabling Diagnostic Logs to Event Hub..."
az monitor diagnostic-settings create \
    --name "$STORAGEADITLOGS" \
    --resource "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --resource-type "Microsoft.Storage/storageAccounts" \
    --logs '[{"category": "StorageRead", "enabled": true}, {"category": "StorageWrite", "enabled": true}, {"category": "StorageDelete", "enabled": true}]' \
    --event-hub-rule "$EVENT_HUB_AUTH_RULE_ID" \
 

if [[ $? -eq 0 ]]; then
    echo "✅ Diagnostic logs successfully enabled!"
else
    echo "❌ Failed to enable diagnostic logs."
    exit 1
fi
