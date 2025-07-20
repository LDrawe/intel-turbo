#! /bin/bash

cores=$(nproc --all)
for ((core=0; core<cores; core++)); do

    wrmsr -p${core} 0x1a0 0x850089

    state=$(sudo rdmsr -p${core} 0x1a0 -f 38:38)
    if [[ $state -eq 1 ]]; then
        echo "Turbo Boost disabled for Core ${core}"
    else
        echo "Turbo Boost enabled for Core ${core}"
    fi
done

# Set CPU governor to performance for all cores
for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo performance | tee "$f"
done
