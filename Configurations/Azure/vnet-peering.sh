#!/usr/bin/env bash
set -euo pipefail

echo "=============================================="
echo "        Azure Virtual Network Peering         "
echo "            by Github.com/M4s00m              "
echo "=============================================="
echo ""

# ---------- Inputs ----------
read -p "Enter Resource Group of VNet-1: " RG1
read -p "Enter VNet-1 Name: " VNET1

read -p "Enter Resource Group of VNet-2: " RG2
read -p "Enter VNet-2 Name: " VNET2

read -p "Allow forwarded traffic? (y/n, default y): " FORWARD
read -p "Allow gateway transit? (y/n, default n): " GATEWAY

FORWARD=${FORWARD:-y}
GATEWAY=${GATEWAY:-n}

# ---------- Resolve VNet IDs ----------
echo ""
echo "🔍 Fetching VNet IDs..."

VNET1_ID=$(az network vnet show \
  --resource-group "$RG1" \
  --name "$VNET1" \
  --query id -o tsv)

VNET2_ID=$(az network vnet show \
  --resource-group "$RG2" \
  --name "$VNET2" \
  --query id -o tsv)

# ---------- Peering Names ----------
PEERING_1_TO_2="${VNET1}-to-${VNET2}"
PEERING_2_TO_1="${VNET2}-to-${VNET1}"

# ---------- Review ----------
echo ""
echo "============= REVIEW ============="
echo "VNet-1           : $VNET1 ($RG1)"
echo "VNet-2           : $VNET2 ($RG2)"
echo "Peering          : Bi-directional between $VNET1 and $VNET2"
echo "Forwarded Traffic: $FORWARD"
echo "Gateway Transit  : $GATEWAY"
echo "=================================="
echo ""

read -p "Proceed with VNet peering? (y/n): " CONFIRM
[[ "$CONFIRM" != "y" ]] && echo "❌ Cancelled." && exit 0

# ---------- Login Check ----------
az account show >/dev/null 2>&1 || az login

# ---------- Peering VNet-1 → VNet-2 ----------
echo ""
echo "➡ Creating peering: $PEERING_1_TO_2"

az network vnet peering create \
  --resource-group "$RG1" \
  --vnet-name "$VNET1" \
  --name "$PEERING_1_TO_2" \
  --remote-vnet "$VNET2_ID" \
  --allow-vnet-access \
  $( [[ "$FORWARD" == "y" ]] && echo "--allow-forwarded-traffic" ) \
  $( [[ "$GATEWAY" == "y" ]] && echo "--allow-gateway-transit" )

# ---------- Peering VNet-2 → VNet-1 ----------
echo ""
echo "➡ Creating peering: $PEERING_2_TO_1"

az network vnet peering create \
  --resource-group "$RG2" \
  --vnet-name "$VNET2" \
  --name "$PEERING_2_TO_1" \
  --remote-vnet "$VNET1_ID" \
  --allow-vnet-access \
  $( [[ "$FORWARD" == "y" ]] && echo "--allow-forwarded-traffic" ) \
  $( [[ "$GATEWAY" == "y" ]] && echo "--use-remote-gateways" )

echo ""
echo "🎉  VNet peering between $VNET1 and $VNET2 created successfully!"
