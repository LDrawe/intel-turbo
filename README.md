# intel-turbo
 Linux script to enable Turbo Boost on Intel CPUs

# Description
 This script is used through a systemd service to enable the Intel Turbo Boost technology on any Linux distribution that supports the intel_pstate frequency driver. To check if your system supports it, open the terminal and run:
 
 ```shell
 cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_driver
```

 It should return ```intel_pstate``` for each CPU thread.

# Installation
First, you need msr-tools installed on your system

## Arch and derivatives

 ```shell
 sudo pacman -S msr-tools
```

Next, the intel folder in opt should be placed under the /opt/ folder of your Linux distribution, while the intel-turbo service file should be placed under the system subfolder of the systemd directory, located in /etc/systemd/system/. I've also put it inside their correct destination folders right in the repository so you can quickly identify where it should be dropped. 

 ```shell
 sudo systemctl enable --now intel-turbo.service
```

 Or, you can just disable turbo manually at your will and not automatically at startup with:
 
 ```shell
 sudo systemctl start intel-turbo.service
```

 While you can check the service status with:

 ```shell
 sudo systemctl status intel-turbo.service
```

 You can also directly ask the system if Turbo Boost is enabled or disabled after applying the service with:

```shell
cat /sys/devices/system/cpu/intel_pstate/no_turbo
```
 This returns:
 
   - ```0``` if turbo is enabled;
   
   - ```1``` if turbo is disabled.

# Removal
 You can disable it with:
 
 ```shell
 sudo systemctl disable --now intel-turbo.service
```

 Once it is disabled, you can proceed to mask the service so it cannot be started by any means. You can do so with:

 ```shell
 sudo systemctl mask intel-turbo.service
 ```

 You can now proceed to permanently remove the files from your system. You need to delete both the intel folder from /opt/ and the systemd file for the service.

```shell
sudo rm -r /opt/intel/

sudo rm /etc/systemd/system/intel-turbo.service 
```

# Usage outside of systemd
 Not all Linux distributions come with the systemd daemon, but they may use other alternatives like OpenRC, runit or s6. In this case, you can still use the scripts but you can't enable them at startup with
 the method written above. What you can do instead is copy the intel folder in your system's /opt/ and follow one of the other methods listed [here](https://www.baeldung.com/linux/run-script-on-startup) to
 enable their autoexecution at startup. 
 If you only want to execute them manually at your own pace, you can do so by opening the terminal and writing one of these two commands.

 The first disables Turbo Boost, the second enables it.

```shell
sudo ./opt/intel/intel_turbo.sh
```

 As an example, we can use the Cron Job method to automatically run one of these two scripts at startup on non-systemd distributions. To do so, you have to first make sure that cronie is installed on your system.
 Open the terminal, and do the following:

- If you are on Debian or Ubuntu, type

  ```shell
  sudo apt install cronie
  ```

- On Fedora or RHEL, type

  ```shell
  sudo yum install cronie
  ```

- On Arch Linux and its derivatives, type

  ```shell
  sudo pacman -S cronie
  ```
   
 You can check if the installation was successful with:

 ```shell
 crond -V
 ```

 Now we need to edit the cron table to add our task which runs one of the two custom scripts on startup. Assuming we want to run the script to disable turbo, type:

 ```shell
 crontab -e
 ```

 Then add said task using the @reboot expression, which executes the code once at startup:

 ```shell
 @reboot sh /opt/intel/intel_turbo.sh
 ```

 If you want to remove the script in the future, first you need to delete the task from the cron table, typing again ```crontab -e``` and removing the line previously added.
 You can then proceed to delete all files from your system, following the same method in [Removal](https://github.com/LDrawe/intel-turbo/edit/main/README.md#removal):

 ```shell
 sudo rm -r /opt/intel/

 sudo rm /etc/systemd/system/intel-noturbo.service /etc/systemd/system/intel-turbo.service 
 ```

# License
 - This project is distributed under the [GNU General Public License v3.0](https://github.com/ShyVortex/intel-turbo/blob/main/LICENSE).
 - Copyright of [@ShyVortex](https://github.com/ShyVortex), 2023.
