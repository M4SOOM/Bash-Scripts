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
echo "================================================"
echo ""

read -p "Proceed with VM creation? (y/n): " CONFIRM
[[ "$CONFIRM" != "y" ]] && echo "❌ Cancelled." && exit 0

# ---------- Login Check ----------
az account show >/dev/null 2>&1 || az login

# ---------- VM Creation ----------
echo ""
echo "🚀 Creating Virtual Machine(s)..."

if [[ "$VM_COUNT" -eq 1 ]]; then
  # ---- Single VM ----
  VM_NAME="$VM_NAME_INPUT"

  echo "➡ Creating single VM: $VM_NAME"

  az vm create \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --name "$VM_NAME" \
    --image "$IMAGE" \
    --size "$VM_SIZE" \
    --admin-username "$ADMIN_USER" \
    --generate-ssh-keys \
    --os-disk-size-gb "$OS_DISK_SIZE" \
    --storage-sku "$STORAGE_SKU"

  echo "✅ VM $VM_NAME created successfully"

else
  # ---- Multiple VMs ----
  for i in $(seq 1 "$VM_COUNT"); do
    VM_NAME="${VM_NAME_INPUT}-${i}"

    echo "➡ Creating VM: $VM_NAME"

    az vm create \
      --resource-group "$RESOURCE_GROUP" \
      --location "$LOCATION" \
      --name "$VM_NAME" \
      --image "$IMAGE" \
      --size "$VM_SIZE" \
      --admin-username "$ADMIN_USER" \
      --generate-ssh-keys \
      --os-disk-size-gb "$OS_DISK_SIZE" \
      --storage-sku "$STORAGE_SKU"

    echo "✅ VM $VM_NAME created successfully"
  done
fi

