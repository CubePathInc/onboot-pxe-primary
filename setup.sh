#!/usr/bin/env bash
# Reorders UEFI boot entries so PXE/Network entries are first and sets next boot to PXE

run_with_sudo() {
    if [ "$(id -u)" -ne 0 ]; then
        sudo "$@"
    else
        "$@"
    fi
}

install_efibootmgr() {
    if command -v apt-get >/dev/null 2>&1; then
        run_with_sudo apt-get update
        run_with_sudo apt-get install -y efibootmgr
    elif command -v dnf >/dev/null 2>&1; then
        run_with_sudo dnf install -y efibootmgr
    elif command -v yum >/dev/null 2>&1; then
        run_with_sudo yum install -y efibootmgr
    elif command -v zypper >/dev/null 2>&1; then
        run_with_sudo zypper install -y efibootmgr
    elif command -v pacman >/dev/null 2>&1; then
        run_with_sudo pacman -S --noconfirm efibootmgr
    else
        echo "Could not detect your package manager. Please install 'efibootmgr' manually."
        exit 1
    fi
}

if ! command -v efibootmgr >/dev/null 2>&1; then
    echo "efibootmgr is not installed. Installing..."
    install_efibootmgr
fi

if [ ! -d "/sys/firmware/efi" ]; then
    echo "This system is not UEFI."
    exit 1
fi

efibootmgr_output="$(run_with_sudo efibootmgr)"
pxe_entries=$(echo "$efibootmgr_output" | grep -iE "pxe|network" | cut -c 5-8)

if [ -z "$pxe_entries" ]; then
    echo "No PXE or Network entries found."
    exit 1
fi

new_order=""
for entry in $pxe_entries; do
    new_order+="$entry,"
done

other_entries=$(echo "$efibootmgr_output" | grep -E "Boot[0-9]" | grep -viE "pxe|network" | cut -c 5-8)
for entry in $other_entries; do
    new_order+="$entry,"
done

new_order="${new_order%,}"
echo "Reordering boot entries to: $new_order"
run_with_sudo efibootmgr -o "$new_order" || {
    echo "Failed to set boot order."
    exit 1
}

echo "Boot order updated."
run_with_sudo efibootmgr

first_pxe=$(echo "$pxe_entries" | awk 'NR==1 {print $1}')
echo "Setting next boot to PXE (Boot$first_pxe)..."
run_with_sudo efibootmgr -n "$first_pxe" || {
    echo "Failed to set next boot."
    exit 1
}

echo "Next boot set to PXE."
