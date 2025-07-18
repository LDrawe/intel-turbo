#! /bin/bash

cores=$(cat /proc/cpuinfo | grep processor | awk '{print $3}')
for core in $cores; do

    sudo wrmsr -p${core} 0x1a0 0x850089

    state=$(sudo rdmsr -p${core} 0x1a0 -f 38:38)
    if [[ $state -eq 1 ]]; then
        echo "core ${core}: disabled"
    else
        echo "core ${core}: enabled"
    fi
done

# Set CPU governor to performance for all cores
for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo performance | sudo tee "$f"
done
