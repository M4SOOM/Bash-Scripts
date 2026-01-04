#!/usr/bin/env bash
set -euo pipefail

echo "=============================================="
echo "        Azure Virtual Networks Deployment     "
echo "            by Github.com/M4s00m              "
echo "=============================================="
echo ""

# ---------- Inputs ----------
read -p "Enter Resource Group name: " RESOURCE_GROUP
read -p "Enter Location (e.g. eastus): " LOCATION
read -p "Enter VNet Name (or Base Name if multiple): " VNET_NAME_INPUT
read -p "Enter number of VNets to create (default 1): " VNET_COUNT
read -p "Enter Address Prefix (e.g. 10.0.0.0/16): " ADDRESS_PREFIX
read -p "Enter Subnet Name (Click Enter for default 'subnet-1'): " SUBNET_NAME
SUBNET_NAME=${SUBNET_NAME:-subnet-1}
read -p "Enter Subnet CIDR (Click "Enter" to get recommendations): " SUBNET_PREFIX

if [[ -z "$SUBNET_PREFIX" ]]; then
  BASE_IP=$(echo "$ADDRESS_PREFIX" | cut -d'/' -f1)

  echo ""
  echo "No subnet CIDR provided. Recommended options:"
  echo "1) ${BASE_IP%.*}.0/24   (Small subnet)"
  echo "2) ${BASE_IP%.*}.1/24"
  echo "3) ${BASE_IP%.*}.0/23   (Medium subnet)"
  echo "4) ${BASE_IP%.*}.0/22   (Large subnet)"
  echo "5) Enter custom subnet CIDR"

  read -p "Select option (1-5): " SUBNET_CHOICE

  case $SUBNET_CHOICE in
    1) SUBNET_PREFIX="${BASE_IP%.*}.0/24" ;;
    2) SUBNET_PREFIX="${BASE_IP%.*}.1/24" ;;
    3) SUBNET_PREFIX="${BASE_IP%.*}.0/23" ;;
    4) SUBNET_PREFIX="${BASE_IP%.*}.0/22" ;;
    5) read -p "Enter custom subnet CIDR: " SUBNET_PREFIX ;;
    *) echo "❌ Invalid subnet choice"; exit 1 ;;
  esac
fi

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
echo "Subnet Name    : $SUBNET_NAME"
echo "Subnet CIDR    : $SUBNET_PREFIX"

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
echo "🚀  Creating Virtual Network(s)..."

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
  --address-prefixes "$ADDRESS_PREFIX" \
  --subnet-name "$SUBNET_NAME" \
  --subnet-prefixes "$SUBNET_PREFIX"

  echo "✅   VNet $VNET_NAME created"
done

echo ""
echo "🎉  The VNet(s) created successfully!"
