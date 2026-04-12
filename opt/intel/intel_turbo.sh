#!/bin/bash

# Check if running as root (required for wrmsr)
if [ "$EUID" -ne 0 ]; then
  printf "Please run this script as root (sudo).\n"
  exit 1
fi

# Check for required dependencies (msr-tools)
command -v rdmsr >/dev/null || { printf "Error: 'rdmsr' not found. Please install msr-tools.\n"; exit 1; }
command -v wrmsr >/dev/null || { printf "Error: 'wrmsr' not found. Please install msr-tools.\n"; exit 1; }

# Set default action to "on" if no parameter is passed (e.g., ./turbo.sh)
ACTION=${1:-on}
# Convert string to lowercase
ACTION=${ACTION,,}

# Check if the passed parameter is valid
if [[ "$ACTION" != "on" && "$ACTION" != "off" ]]; then
    printf "Invalid usage. Try: %s [on|off]\n" "$0"
    exit 1
fi

# Define color variables for printf
GREEN='\e[32m'
RED='\e[31m'
NC='\e[0m'

printf "Applying Turbo Boost configuration: %s\n" "$ACTION"
printf "----------------------------------------\n"

# Read the current hexadecimal value from Core 0 as the baseline
current_hex=$(rdmsr -p0 0x1a0) || { printf "Error: Failed to read MSR. Is the 'msr' module loaded?\n"; exit 1; }
current_val=$((0x$current_hex))

# 7. Bitwise Math depending on the parameter
if [ "$ACTION" == "on" ]; then
    # Enable Turbo (Set bit 38 to 0 using Bitwise AND with NOT)
    new_val=$(( current_val & ~(1 << 38) ))
    pstate_val=0
    state_msg="${GREEN}ENABLED${NC}"
else
    # Disable Turbo (Set bit 38 to 1 using Bitwise OR)
    new_val=$(( current_val | (1 << 38) ))
    pstate_val=1
    state_msg="${RED}DISABLED${NC}"
fi

# Convert the new formatted numeric value back to hexadecimal
new_hex=$(printf "0x%x" $new_val)

# Modify the MSR for all cores simultaneously (-a flag)
wrmsr -a 0x1a0 $new_hex

# After modifying the hardware, ensure the Linux pstate driver aligns
# The error output (2>) is sent to /dev/null to quietly ignore read-only file blocks
echo $pstate_val > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null

printf "Turbo Boost is now %b for all cores (Value written: %s)\n" "$state_msg" "$new_hex"
printf "----------------------------------------\n"
