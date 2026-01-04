#!/bin/bash

RESOURCE_GROUP="XXXXXXXXXX"  #set-the-RG-name-accordingly
LOCATION="XXXXXXXXX"  #set-location-accordingly
VM_NAME="XXXXXXXXX"  #set-custom-Virual-Machine-name-accordingly
VM_SIZE="Standard_B1s/ Standard_B2s / Standard_D2s_v3 / Standard_D4s_v3"  #Choose-one-virual-machine-size-accordingly
IMAGE="XXXXXXXXX" #set-image-name-accordingly
ADMIN_USER="azureuser"  #set-name-accordingly

echo "Creating Virtual Machine..."
az vm create \
  --resource-group $RESOURCE_GROUP \
  --name $VM_NAME \
  --image $IMAGE \
  --size $VM_SIZE \
  --admin-username $ADMIN_USER \
  --generate-ssh-keys  #helps-in-generating-SSH-keys-automatically

echo "VM creation completed successfully!"
