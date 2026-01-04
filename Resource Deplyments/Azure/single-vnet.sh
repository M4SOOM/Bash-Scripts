#!/usr/bin/env bash
set -euo pipefail

RESOURCE_GROUP="XXXXXXXXXXXXXX"  #set-the-RG-name-accordingly
LOCATION="XXXXXXXXXXX"  #set-location-accordingly
VNET_NAME="XXXXXXXXXXXXXX"  #set-custom-VNET-name-accordingly
ADDRESS_PREFIX="XX.XX.XX.XX/XX" #set-the-CIDR-Range-accordingly

#---------------Don't change anything below-----------------------#

echo "Creating VNet: $VNET_NAME"

az network vnet create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VNET_NAME" \
  --location "$LOCATION" \
  --address-prefixes "$ADDRESS_PREFIX"

echo "VNet $VNET_NAME created successfully 🚀"
