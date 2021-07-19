set -o pipefail
set -o errtrace
set -o nounset
set -o errexit
set -a

# Scratch mount is the device which will be mounted on /mnt
# and generally used for logs, core dumps etc.
if ! $(mount | grep -q /mnt) ; then
    # Detected NVME drives
    # They do not always have a consistent drive number, this will scan for the drives slot in the hypervisor
    # and mount the correct ones, with sda1 always being the base disk and sdb being the extra, larger, disk
    if lshw | grep nvme &>/dev/null; then
        for blkdev in $(nvme list | awk '/^\/dev/ { print $1 }'); do
            mapping=$(nvme id-ctrl --raw-binary "$blkdev" | cut -c3073-3104 | tr -s ' ' | sed 's/ $//g')
            if [[ $mapping == "sda1" ]]; then
                echo "$blkdev is $mapping skipping..."
            elif [[ $mapping == "sdb" ]]; then
                echo "$blkdev is $mapping formatting and mounting..."
                mkfs -t ext4 $blkdev
                echo "$blkdev    /mnt    ext4    defaults,comment=cloudconfig    0    2" >> /etc/fstab
                mount $blkdev
            else
                echo "detected unknown drive letter $blkdev: $mapping. Skipping..."
            fi
        done
    else
        echo "Configuring ${device_name}..."
        mkfs -t ext4 ${device_name}
        echo "${device_name}    /mnt    ext4    defaults,comment=cloudconfig    0    2" >> /etc/fstab
        mount ${device_name}
    fi
else
    echo "detected drive already mounted to /mnt, skipping mount..."
    lsblk | grep mnt
fi
