# intel-turbo

Enable Intel® Turbo Boost on Linux systems using the intel_pstate frequency driver

This repository provides a lightweight and safe Linux script for reactivating Intel Turbo Boost on systems where the feature is unavailable through BIOS/UEFI or locked at firmware level, even when using administrative privileges.

The project exists because, in Linux, the standard Turbo Boost control file:

```bash
/sys/devices/system/cpu/intel_pstate/no_turbo
```
cannot be modified — not even by the root user — on certain motherboards, firmwares or aftermarket boards.
Because of this restriction, Turbo Boost cannot be enabled through standard Linux interfaces, even on CPUs that fully support the feature.
To restore the missing functionality, the script modifies the appropriate Model-Specific Register (MSR) directly.

---

## 🔍 Background

In some systems—especially those with custom, replacement or generic motherboards—BIOS/UEFI may omit or lock Turbo Boost configuration options.
On Linux, unlike Windows where tools like ThrottleStop exist, there is no built-in mechanism to re-enable Turbo Boost when firmware restrictions are in place.

Attempts to use the intel_pstate interface fail because:

The no_turbo control file is read-only,

Permissions cannot be changed,

And its write protection is enforced at kernel level, not filesystem level.

Therefore, the only reliable alternative is accessing the relevant MSR and flipping the correct bit manually.

## ⚙️ How It Works

Intel CPUs expose Turbo Boost control through the MSR:

Register: IA32_MISC_ENABLE

Address: 0x1A0

Bit 38: Turbo Mode Disable

1 → Turbo Boost disabled

0 → Turbo Boost enabled

To enable Turbo Boost, the script clears bit 38 using:

```bash
wrmsr -p $CORE 0x1a0 0x850089
```

(This value depends on preserving other bits from the register — the script handles it safely.)
The script runs through all CPU cores and applies the patch.

---

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

## Manual or Alternative Startup Methods

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

## Removal

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


## License

* Licensed under the [GNU General Public License v3.0](https://github.com/ShyVortex/intel-turbo/blob/main/LICENSE).
* Copyright © [@ShyVortex](https://github.com/ShyVortex), 2023.
* Copyright © [@LDrawe](https://github.com/LDrawe), 2025 — modifications to enable Turbo Boost.

