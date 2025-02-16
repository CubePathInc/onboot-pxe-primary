# onboot-pxe-primary

Reorder UEFI boot entries so PXE/Network is first, then set the next boot to PXE.

## How to Use

```bash
wget -qO- https://raw.githubusercontent.com/CubePathInc/onboot-pxe-primary/main/setup.sh | sudo bash
