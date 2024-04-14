#!/bin/bash

# Check if VirtualBox is installed and get the version
VB_VERSION=$(VBoxManage --version)
if [ $? -eq 0 ]; then
    echo "VirtualBox version: $VB_VERSION"
else
    echo "VirtualBox is not installed on this system."
    exit 1
fi

# Check for installed extension packs
echo "Checking for installed extension packs:"
VBoxManage list extpacks

# List all VirtualBox VMs
echo "Listing all VirtualBox VMs:"
VBoxManage list vms

# Get detailed information for all VMs
echo "Getting detailed information for all VMs:"
VBoxManage list vms | cut -d '"' -f 2 | while read VM_NAME; do
    echo "Details for VM: $VM_NAME"
    VBoxManage showvminfo "$VM_NAME" --machinereadable
done

