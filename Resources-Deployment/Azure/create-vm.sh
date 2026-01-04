#!/bin/bash

set -e

echo "============================================"
echo "        Azure Virtual Machine Deployment    "
echo "            by Github.com/M4s00m            "
echo "============================================"
echo ""

# ---------- Basic Inputs ----------
read -p "Enter Resource Group name: " RESOURCE_GROUP
read -p "Enter Location (e.g. eastus): " LOCATION
read -p "Enter VM Name (or Base Name if multiple): " VM_NAME_INPUT
read -p "Enter number of VMs to create (default 1): " VM_COUNT

ADMIN_USER="azureuser"

# Default to 1 if empty
VM_COUNT=${VM_COUNT:-1}

if [[ "$VM_COUNT" -le 0 ]]; then
  echo "❌ Number of VMs must be >= 1"
  exit 1
fi

# ---------- VM Size ----------
echo ""
echo "Select VM Size:"
echo "1) Standard_B1s"
echo "2) Standard_B2s"
echo "3) Standard_B2ms"
echo "4) Standard_D2s_v3"
echo "5) Standard_D4s_v3"
echo "6) Standard_E2s_v3"
echo "7) Standard_E4s_v3"
echo "8) Standard_F2s_v2"
echo "9) Standard_F4s_v2"
echo "10) Standard_L4s"
read -p "Enter choice (1-10): " VM_CHOICE

case $VM_CHOICE in
  1) VM_SIZE="Standard_B1s" ;;
  2) VM_SIZE="Standard_B2s" ;;
  3) VM_SIZE="Standard_B2ms" ;;
  4) VM_SIZE="Standard_D2s_v3" ;;
  5) VM_SIZE="Standard_D4s_v3" ;;
  6) VM_SIZE="Standard_E2s_v3" ;;
  7) VM_SIZE="Standard_E4s_v3" ;;
  8) VM_SIZE="Standard_F2s_v2" ;;
  9) VM_SIZE="Standard_F4s_v2" ;;
  10) VM_SIZE="Standard_L4s" ;;
  *) echo "❌ Invalid VM size choice"; exit 1 ;;
esac

# ---------- OS Image ----------
echo ""
echo "Select OS Image:"
echo "1) Ubuntu 22.04 LTS"
echo "2) Ubuntu 24.04 LTS"
echo "3) Ubuntu 20.04 LTS"
echo "4) Debian 12"
echo "5) CentOS Stream 9"
echo "6) Red Hat Enterprise Linux 9"
echo "7) Rocky Linux 9"
echo "8) AlmaLinux 9"
echo "9) Windows Server 2019"
echo "10) Windows Server 2022"
read -p "Enter choice (1-10): " IMAGE_CHOICE

case $IMAGE_CHOICE in
  1) IMAGE="Ubuntu2204" ;;
  2) IMAGE="Ubuntu2404" ;;
  3) IMAGE="Ubuntu2004" ;;
  4) IMAGE="Debian12" ;;
  5) IMAGE="CentOSStream9" ;;
  6) IMAGE="RHEL9_2" ;;
  7) IMAGE="RockyLinux9" ;;
  8) IMAGE="AlmaLinux9" ;;
  9) IMAGE="Win2019Datacenter" ;;
  10) IMAGE="Win2022Datacenter" ;;
  *) echo "❌ Invalid image choice"; exit 1 ;;
esac

# ---------- Disk Size ----------
echo ""
echo "Select OS Disk Size:"
echo "1) 30 GB"
echo "2) 40 GB"
echo "3) 50 GB"
echo "4) 64 GB"
echo "5) 80 GB"
echo "6) 100 GB"
echo "7) 120 GB"
echo "8) 128 GB"
echo "9) 60 GB"
echo "10) 70 GB"
read -p "Enter choice (1-10): " DISK_CHOICE

case $DISK_CHOICE in
  1) OS_DISK_SIZE=30 ;;
  2) OS_DISK_SIZE=40 ;;
  3) OS_DISK_SIZE=50 ;;
  4) OS_DISK_SIZE=64 ;;
  5) OS_DISK_SIZE=80 ;;
  6) OS_DISK_SIZE=100 ;;
  7) OS_DISK_SIZE=120 ;;
  8) OS_DISK_SIZE=128 ;;
  9) OS_DISK_SIZE=60 ;;
  10) OS_DISK_SIZE=70 ;;
  *) echo "❌ Invalid disk size choice"; exit 1 ;;
esac

# ---------- Storage SKU ----------
echo ""
echo "Select Storage SKU:"
echo "1) Standard_LRS (Standard HDD – cheapest)"
echo "2) StandardSSD_LRS"
echo "3) Premium_LRS"
echo "4) UltraSSD_LRS"
echo "5) Premium_ZRS"
echo "6) StandardSSD_ZRS"
echo "7) PremiumV2_LRS"
echo "8) StandardSSD_GRS"
echo "9) StandardSSD_RAGRS"
echo "10) Standard_LRS (Fallback)"
read -p "Enter choice (1-10): " SKU_CHOICE

case $SKU_CHOICE in
  1) STORAGE_SKU="Standard_LRS" ;;
  2) STORAGE_SKU="StandardSSD_LRS" ;;
  3) STORAGE_SKU="Premium_LRS" ;;
  4) STORAGE_SKU="UltraSSD_LRS" ;;
  5) STORAGE_SKU="Premium_ZRS" ;;
  6) STORAGE_SKU="StandardSSD_ZRS" ;;
  7) STORAGE_SKU="PremiumV2_LRS" ;;
  8) STORAGE_SKU="StandardSSD_GRS" ;;
  9) STORAGE_SKU="StandardSSD_RAGRS" ;;
  10) STORAGE_SKU="Standard_LRS" ;;
  *) echo "❌ Invalid storage SKU choice"; exit 1 ;;
esac

# ---------- Virtual Network & Subnet----------

DEFAULT_VNET_NAME="${VM_NAME_INPUT}-vnet"
DEFAULT_SUBNET_NAME="${VM_NAME_INPUT}-subnet"
VNET_ADDRESS="10.0.0.0/16"
SUBNET_ADDRESS="10.0.1.0/24"

read -p "Enter Virtual Network name (press Enter to auto-create): " VNET_NAME
read -p "Enter Subnet name (press Enter to auto-create): " SUBNET_NAME

# Auto-assign defaults if empty
VNET_NAME=${VNET_NAME:-$DEFAULT_VNET_NAME}
SUBNET_NAME=${SUBNET_NAME:-$DEFAULT_SUBNET_NAME}

echo ""
echo "Using VNet:   $VNET_NAME"
echo "Using Subnet: $SUBNET_NAME"

# Check if VNet exists
if ! az network vnet show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VNET_NAME" &>/dev/null; then

  echo "🔧 VNet not found. Creating VNet + Subnet..."

  az network vnet create \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --name "$VNET_NAME" \
    --address-prefix "$VNET_ADDRESS" \
    --subnet-name "$SUBNET_NAME" \
    --subnet-prefix "$SUBNET_ADDRESS"

else
  echo "✅ VNet exists."

  # Check if Subnet exists
  if ! az network vnet subnet show \
    --resource-group "$RESOURCE_GROUP" \
    --vnet-name "$VNET_NAME" \
    --name "$SUBNET_NAME" &>/dev/null; then

    echo "🔧 Subnet not found. Creating subnet..."

    az network vnet subnet create \
      --resource-group "$RESOURCE_GROUP" \
      --vnet-name "$VNET_NAME" \
      --name "$SUBNET_NAME" \
      --address-prefix "$SUBNET_ADDRESS"
  else
    echo "✅ Subnet exists."
  fi
fi

# Get Subnet ID
SUBNET_ID=$(az network vnet subnet show \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --name "$SUBNET_NAME" \
  --query id -o tsv)

# ---------- Network Security Group ----------
echo ""
echo "Select NIC Network Security Group option:"
echo "1) None"
echo "2) Basic"
echo "3) Advanced"
read -p "Enter choice (1-3): " NSG_CHOICE

NSG_NAME="${VM_NAME_INPUT}-nsg"

if [[ "$NSG_CHOICE" != "1" ]]; then
  az network nsg create \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --name "$NSG_NAME"
fi

# ---------- Inbound Ports ----------
if [[ "$NSG_CHOICE" != "1" ]]; then
  echo ""
  echo "Select inbound ports (space separated):"
  echo "22 (SSH) 80 (HTTP) 443 (HTTPS) 3389 (RDP)"
  read -p "Ports: " PORTS

  PRIORITY=100
  for PORT in $PORTS; do
    az network nsg rule create \
      --resource-group "$RESOURCE_GROUP" \
      --nsg-name "$NSG_NAME" \
      --name "allow-$PORT" \
      --priority $PRIORITY \
      --access Allow \
      --protocol Tcp \
      --direction Inbound \
      --source-address-prefix "*" \
      --destination-port-range "$PORT"
    PRIORITY=$((PRIORITY+10))
  done
fi

# ---------- Review ----------
echo ""
echo "============= REVIEW CONFIGURATION ============="
echo "Resource Group : $RESOURCE_GROUP"
echo "Location       : $LOCATION"
echo "VM Name        : $VM_NAME"
echo "VM Size        : $VM_SIZE"
echo "OS Image       : $IMAGE"
echo "Admin User     : $ADMIN_USER"
echo "OS Disk Size   : ${OS_DISK_SIZE} GB"
echo "Storage SKU    : $STORAGE_SKU"
echo "Number of VMs  : $VM_COUNT"

if [[ "$VM_COUNT" -eq 1 ]]; then
  echo "VM Name        : $VM_NAME_INPUT"
else
  echo "VM Name Format : ${VM_NAME_INPUT}-<number>"
fi
echo "VNet/Subnet    : $VNET_NAME / $SUBNET_NAME"
echo "NSG Option     : $NSG_CHOICE"
[[ "$NSG_CHOICE" != "1" ]] && echo "Inbound Ports  : $PORTS"
echo "================================================"
echo ""

read -p "Proceed with VM creation? (y/n): " CONFIRM
[[ "$CONFIRM" != "y" ]] && echo "❌ Cancelled." && exit 0

# ---------- Login Check ----------
az account show >/dev/null 2>&1 || az login

# ---------- VM Creation ----------
echo ""
echo "🚀 Creating Virtual Machine(s)..."

for i in $(seq 1 "$VM_COUNT"); do

  # ---- Naming Logic ----
  if [[ "$VM_COUNT" -eq 1 ]]; then
    VM_NAME="$VM_NAME_INPUT"
  else
    VM_NAME="${VM_NAME_INPUT}-${i}"
  fi

  NIC_NAME="${VM_NAME}-nic"

  echo ""
  echo "➡ Creating NIC: $NIC_NAME"

  # ---- Create NIC (attach NSG only if selected) ----
  if [[ "$NSG_CHOICE" -eq 1 ]]; then
    az network nic create \
      --resource-group "$RESOURCE_GROUP" \
      --location "$LOCATION" \
      --name "$NIC_NAME" \
      --subnet "$SUBNET_ID"
  else
    az network nic create \
      --resource-group "$RESOURCE_GROUP" \
      --location "$LOCATION" \
      --name "$NIC_NAME" \
      --subnet "$SUBNET_ID" \
      --network-security-group "$NSG_NAME"
  fi

  echo "➡ Creating VM: $VM_NAME"

  # ---- Create VM using the NIC ----
  az vm create \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --name "$VM_NAME" \
    --image "$IMAGE" \
    --size "$VM_SIZE" \
    --admin-username "$ADMIN_USER" \
    --generate-ssh-keys \
    --nics "$NIC_NAME" \
    --os-disk-size-gb "$OS_DISK_SIZE" \
    --storage-sku "$STORAGE_SKU"

  echo "✅ VM $VM_NAME created successfully"
done

