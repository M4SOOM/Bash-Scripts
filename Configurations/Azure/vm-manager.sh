#!/usr/bin/env bash
set -euo pipefail

# ============================
# GLOBAL CONFIG
# ============================
RESOURCE_GROUP=""
VM_NAME=""
LOCATION="eastus"

# ============================
# HELPER FUNCTIONS
# ============================
pause() {
  read -rp "Press ENTER to continue..."
}

select_vm() {
  read -rp "Enter Resource Group: " RESOURCE_GROUP
  read -rp "Enter VM Name: " VM_NAME
}

# ============================
# VM POWER OPERATIONS
# ============================
start_vm() {
  select_vm
  az vm start -g "$RESOURCE_GROUP" -n "$VM_NAME"
}

stop_vm() {
  select_vm
  az vm stop -g "$RESOURCE_GROUP" -n "$VM_NAME"
}

deallocate_vm() {
  select_vm
  az vm deallocate -g "$RESOURCE_GROUP" -n "$VM_NAME"
}

restart_vm() {
  select_vm
  az vm restart -g "$RESOURCE_GROUP" -n "$VM_NAME"
}

resize_vm() {
  select_vm
  read -rp "Enter new VM size (e.g. Standard_B2s): " NEW_SIZE
  az vm resize -g "$RESOURCE_GROUP" -n "$VM_NAME" --size "$NEW_SIZE"
}

# ============================
# DISK OPERATIONS
# ============================
attach_disk() {
  select_vm
  read -rp "Disk name: " DISK_NAME
  read -rp "Disk size (GB): " DISK_SIZE

  az vm disk attach \
    -g "$RESOURCE_GROUP" \
    --vm-name "$VM_NAME" \
    --name "$DISK_NAME" \
    --size-gb "$DISK_SIZE" \
    --new
}

snapshot_disk() {
  read -rp "Disk ID: " DISK_ID
  read -rp "Snapshot name: " SNAP_NAME

  az snapshot create \
    -g "$RESOURCE_GROUP" \
    --source "$DISK_ID" \
    --name "$SNAP_NAME"
}

# ============================
# NETWORK & ACCESS
# ============================
enable_bastion() {
  read -rp "VNet name: " VNET_NAME
  az network bastion create \
    -g "$RESOURCE_GROUP" \
    -n bastion-host \
    --vnet-name "$VNET_NAME" \
    --location "$LOCATION"
}

configure_nsg() {
  read -rp "NSG name: " NSG_NAME
  az network nsg rule create \
    -g "$RESOURCE_GROUP" \
    --nsg-name "$NSG_NAME" \
    -n Allow-SSH \
    --priority 100 \
    --destination-port-range 22 \
    --access Allow \
    --protocol Tcp
}

# ============================
# SECURITY
# ============================
disable_password_auth() {
  select_vm
  az vm run-command invoke \
    -g "$RESOURCE_GROUP" \
    -n "$VM_NAME" \
    --command-id RunShellScript \
    --scripts "sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && sudo systemctl restart sshd"
}

enable_managed_identity() {
  select_vm
  az vm identity assign -g "$RESOURCE_GROUP" -n "$VM_NAME"
}

# ============================
# PATCHING & EXTENSIONS
# ============================
patch_os() {
  select_vm
  az vm run-command invoke \
    -g "$RESOURCE_GROUP" \
    -n "$VM_NAME" \
    --command-id RunShellScript \
    --scripts "sudo apt update && sudo apt upgrade -y"
}

# ============================
# MONITORING
# ============================
enable_vm_insights() {
  az monitor vm-insights enable -g "$RESOURCE_GROUP" -n "$VM_NAME"
}

# ============================
# COST OPTIMIZATION
# ============================
auto_shutdown() {
  select_vm
  read -rp "Shutdown time (HHMM, UTC): " TIME
  az vm auto-shutdown \
    -g "$RESOURCE_GROUP" \
    -n "$VM_NAME" \
    --time "$TIME"
}

# ============================
# BACKUP
# ============================
enable_backup() {
  select_vm
  az backup protection enable-for-vm \
    --resource-group "$RESOURCE_GROUP" \
    --vm "$VM_NAME" \
    --policy-name DefaultPolicy \
    --vault-name RecoveryVault
}

# ============================
# MENU
# ============================
while true; do
  clear
  echo "========= AZURE VM MANAGER ========="
  echo "1) Start VM"
  echo "2) Stop VM"
  echo "3) Deallocate VM"
  echo "4) Restart VM"
  echo "5) Resize VM"
  echo "6) Attach Disk"
  echo "7) Snapshot Disk"
  echo "8) Configure NSG"
  echo "9) Enable Bastion"
  echo "10) Disable Password Login"
  echo "11) Enable Managed Identity"
  echo "12) Patch OS"
  echo "13) Enable VM Insights"
  echo "14) Auto Shutdown"
  echo "15) Enable Backup"
  echo "0) Exit"
  echo "==================================="
  read -rp "Choose an option: " CHOICE

  case $CHOICE in
    1) start_vm ;;
    2) stop_vm ;;
    3) deallocate_vm ;;
    4) restart_vm ;;
    5) resize_vm ;;
    6) attach_disk ;;
    7) snapshot_disk ;;
    8) configure_nsg ;;
    9) enable_bastion ;;
    10) disable_password_auth ;;
    11) enable_managed_identity ;;
    12) patch_os ;;
    13) enable_vm_insights ;;
    14) auto_shutdown ;;
    15) enable_backup ;;
    0) exit 0 ;;
    *) echo "Invalid choice";;
  esac

  pause
done
