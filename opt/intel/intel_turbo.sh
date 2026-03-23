#!/bin/bash

# Check if running as root (required for wrmsr)
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (sudo)."
  exit 1
fi

# Set default action to "on" if no parameter is passed (e.g., ./turbo.sh)
ACTION=${1:-on}
# Convert string to lowercase, preventing errors if the user types "ON" or "Off"
ACTION=${ACTION,,}

# Check if the passed parameter is valid
if [[ "$ACTION" != "on" && "$ACTION" != "off" ]]; then
    echo "Invalid usage. Try: $0 [on|off]"
    echo "If no parameter is passed, the default is 'on'."
    exit 1
fi

GREEN='\e[32m'
RED='\e[31m'
NC='\e[0m' # No Color (Resets to the default terminal color)

cores=$(nproc --all)

echo "Applying Turbo Boost configuration: $ACTION"
echo "----------------------------------------"

for ((core=0; core<cores; core++)); do
    # 1. Read the current hexadecimal value of the register
    current_hex=$(rdmsr -p${core} 0x1a0)

    # 2. Convert the read value to a numeric format that bash understands
    current_val=$((0x$current_hex))

    # 3. Bitwise Math depending on the parameter
    if [ "$ACTION" == "on" ]; then
        # Enable Turbo (Clear bit 38 using Bitwise AND with NOT)
        new_val=$(( current_val & ~(1 << 38) ))
        pstate_val=0
    else
        # Disable Turbo (Set bit 38 to 1 using Bitwise OR)
        new_val=$(( current_val | (1 << 38) ))
        pstate_val=1
    fi

    # 4. Convert the new formatted numeric value back to hexadecimal
    new_hex=$(printf "0x%x" $new_val)

    # 5. Write the modified new value back to the register
    wrmsr -p${core} 0x1a0 $new_hex

    # 6. Ensure the Linux pstate driver follows our manual change
    echo $pstate_val > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null

    # 7. Read only bit 38 to confirm the final state
    state=$(rdmsr -p${core} 0x1a0 -f 38:38)

    if [[ $state -eq 1 ]]; then
        echo -e "Turbo Boost for Core ${core}: ${RED}DISABLED${NC}"
    else
        echo -e "Turbo Boost for Core ${core}: ${GREEN}ENABLED${NC}"
    fi
done

echo "----------------------------------------"
