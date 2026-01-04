#!/usr/bin/env bash
set -euo pipefail

echo "============================================"
echo "        Azure Virtual Netowrks Deployment    "
echo "            by Github.com/M4s00m            "
echo "============================================"
echo ""

# ---------- Inputs ----------
read -p "Enter Resource Group name: " RESOURCE_GROUP
read -p "Enter Location (e.g. eastus): " LOCATION
read -p "Enter VNet Name (or Base Name if multiple): " VNET_NAME_INPUT
read -p "Enter number of VNets to create (default 1): " VNET_COUNT
read -p "Enter Address Prefix (e.g. 10.0.0.0/16): " ADDRESS_PREFIX

# Defaults
VNET_COUNT=${VNET_COUNT:-1}

if [[ "$VNET_COUNT" -le 0 ]]; then
  echo "❌ Number of VNets must be >= 1"
  exit 1
fi

# ---------- Review ----------
echo ""
echo "=========== REVIEW ==========="
echo "Resource Group : $RESOURCE_GROUP"
echo "Location       : $LOCATION"
echo "VNet Count     : $VNET_COUNT"
echo "Address Prefix : $ADDRESS_PREFIX"

if [[ "$VNET_COUNT" -eq 1 ]]; then
  echo "VNet Name      : $VNET_NAME_INPUT"
else
  echo "VNet Name Format : ${VNET_NAME_INPUT}-<number>"
fi
echo "=============================="
echo ""

read -p "Proceed with VNet creation? (y/n): " CONFIRM
[[ "$CONFIRM" != "y" ]] && echo "❌ Cancelled." && exit 0

# ---------- Login Check ----------
az account show >/dev/null 2>&1 || az login

# ---------- VNet Creation ----------
echo ""
echo "🚀 Creating Virtual Network(s)..."

for i in $(seq 1 "$VNET_COUNT"); do

  if [[ "$VNET_COUNT" -eq 1 ]]; then
    VNET_NAME="$VNET_NAME_INPUT"
  else
    VNET_NAME="${VNET_NAME_INPUT}-${i}"
  fi

  echo "➡ Creating VNet: $VNET_NAME"

  az network vnet create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VNET_NAME" \
    --location "$LOCATION" \
    --address-prefixes "$ADDRESS_PREFIX"

  echo "✅ VNet $VNET_NAME created"
done

echo ""
echo "🎉 The VNet(s) created successfully!"

