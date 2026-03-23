# intel-turbo

Enable Intel® Turbo Boost on Linux systems using the ***intel_pstate*** frequency driver

This repository provides a lightweight and safe Linux script to **reactivate Intel Turbo Boost** on systems where the feature is unavailable through BIOS/UEFI or locked at firmware level, even when using administrative privileges.

The project exists because, in Linux, the standard Turbo Boost control file:

```bash
/sys/devices/system/cpu/intel_pstate/no_turbo
```
is read-only, enforced by the kernel, and cannot be modified.
Because of this restriction, Turbo Boost cannot be enabled using standard Linux interfaces, even on CPUs that fully support it.

To restore the missing functionality, this script writes directly to the appropriate Model-Specific Register (MSR).

---

## 🔍 Background

Certain systems — especially laptops with generic, refurbished or non-OEM motherboards — ship with BIOS/UEFI firmware that hides or locks Turbo Boost settings.

Unlike Windows, where tools like ThrottleStop can override firmware limitations, Linux does not provide any user-space mechanism to re-enable Turbo Boost when the firmware prevents it.

Attempts to toggle the intel_pstate interface fail because:

- The no_turbo control file is kernel-protected

- Permission changes do not work

- The protection is enforced inside the kernel, not in the filesystem

Therefore, the only reliable method is to modify the correct MSR and flip the corresponding bit manually.

## ⚙️ How It Works

Intel CPUs expose Turbo Boost control through the Model-Specific Register (MSR):

- **Register:** `IA32_MISC_ENABLE`
- **Address:** `0x1A0`
- **Bit 38:** Turbo Mode Disable
  - `1` → Turbo Boost disabled
  - `0` → Turbo Boost enabled

Writing a hardcoded hex value to this register is dangerous, as it can overwrite other vital CPU settings configured by the system's BIOS. To safely enable or disable Turbo Boost, this script uses **bitwise operations** to target *only* bit 38 while preserving the rest of the register's configuration.

The script operates by:
1. Reading the current 64-bit value of the register for the specific core using `rdmsr`.
2. Applying a dynamic bitmask:
   - **To enable:** Uses bitwise AND with NOT (`~(1 << 38)`) to clear bit 38.
   - **To disable:** Uses bitwise OR (`1 << 38`) to set bit 38.
3. Writing the safely modified value back using `wrmsr`.

The script automatically detects all available CPU cores and applies the patch to each one.

---

## 🔧 Integration with auto-cpufreq

During testing, for some reason auto-cpufreq prevented the CPU frequencies from scaling up beyond the base clock, effectively disabling Turbo Boost.
To avoid this, the systemd service was configured to run after auto-cpufreq finishes its initialization.

## 📦 Installation

### Systemd-Based Systems

1. Clone the repo and enter the folder:

```bash
   git clone https://github.com/LDrawe/intel-turbo.git
   cd intel-turbo
```

2. Copy the files and ensure the script has execution permissions:

   ```bash
   sudo cp -r opt/intel /opt/
   sudo cp etc/systemd/system/intel-turbo.service /etc/systemd/system/
   sudo chmod +x /opt/intel/intel_turbo.sh
   ```

4. To automatically enable Turbo Boost at startup:

   ```bash
   sudo systemctl enable --now intel-turbo.service
   ```

5. (Optional) Check the service status:

   ```bash
   sudo systemctl status intel-turbo.service
   ```

6. You can verify the Turbo Boost status at any time with:

   ```bash
   cat /sys/devices/system/cpu/intel_pstate/no_turbo
   ```

   * `0`: Turbo Boost is **enabled**
   * `1`: Turbo Boost is **disabled**

---

## 🖥️ Manual or Alternative Startup Methods

If your system uses **OpenRC**, **runit**, **s6**, or other init systems, you can still use the script manually or set it to run at startup via alternative methods.

### Manual Execution

```bash
sudo /opt/intel/intel_turbo.sh
```

### Automatic Execution via Cron (Example)

1. Ensure `cronie` is installed:

   * **Debian/Ubuntu**:

     ```bash
     sudo apt install cronie
     ```

   * **Fedora/RHEL**:

     ```bash
     sudo yum install cronie
     ```

   * **Arch Linux**:

     ```bash
     sudo pacman -S cronie
     ```

2. Verify installation:

   ```bash
   crond -V
   ```

3. Edit the crontab:

   ```bash
   crontab -e
   ```

4. Add the following line to enable Turbo Boost at startup:

   ```bash
   @reboot sh /opt/intel/intel_turbo.sh
   ```

---

## 🗑️ Removal

### Systemd

1. Disable and stop the service:

   ```bash
   sudo systemctl disable --now intel-turbo.service
   ```

2. Mask the service to prevent accidental activation:

   ```bash
   sudo systemctl mask intel-turbo.service
   ```

3. Remove installed files:

   ```bash
   sudo rm -r /opt/intel/
   sudo rm /etc/systemd/system/intel-turbo.service
   ```

4. Reboot to apply changes.

---

### Cron or Manual Installation

1. Remove the `@reboot` line from the crontab:

   ```bash
   crontab -e
   ```

2. Delete installed files:

   ```bash
   sudo rm -r /opt/intel/
   ```

---

## Credits

This project is a fork of the original [intel-turbo](https://github.com/ShyVortex/intel-turbo) script by [@ShyVortex](https://github.com/ShyVortex), modified to enable Intel Turbo Boost instead of disabling it.

Fork maintained by [@LDrawe](https://github.com/LDrawe).


## 📄 License

* Licensed under the [GNU General Public License v3.0](https://github.com/ShyVortex/intel-turbo/blob/main/LICENSE).
* Copyright © [@ShyVortex](https://github.com/ShyVortex), 2023.
* Copyright © [@LDrawe](https://github.com/LDrawe), 2025 — modifications to enable Turbo Boost.

