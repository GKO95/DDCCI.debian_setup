# DDC/CI: Debian Setup
This repository contains Shell scripts which automatically install packages required to run DDC/CI software for NVIDIA GPU. DDC/CI packages introduced in this repository are as follows:

* [`ddccontrol`](https://github.com/ddccontrol/ddccontrol)
  * Exclusive to Debian 9 "stretch"
* [`ddcutil`](https://github.com/rockowitz/ddcutil)
  * Available on Debian 9 "stretch" and 10 "buster"

As mentioned above, this repository focuses DDC/CI on NVIDIA graphic card; the Shell scripts does not have graphic card detection, thus should not be used on AMD.

## Changing Linux Repository
> *Reference: https://wiki.debian.org/NvidiaGraphicsDrivers/*

To install NVIDIA graphic packages to Debian distribution, new components needs to be added on Linux repository located in `/etc/apt/sources.list`; change the component from `main` to `main contrib non-free` and update repository.

```
$ sudo apt update
```

## NVIDIA Configuration
> *Reference: http://www.ddcutil.com/nvidia/*

Depending on NVIDIA graphic card, there may require additional modification on NVIDIA parameters. Copy `/usr/share/X11/xorg.conf.d/` directory to `/etc/X11` and modify `90-nvidia_i2c.conf` file as shown below:
```
Section "Device"
    Driver        "nvidia"
    Identifier    "Dev0"
    Option        "RegistryDwords" "RMUseSwI2c=0x01; RMI2cSpeed=100"
    # solves problem of i2c errors with nvidia driver
    # per https://devtalk.nvidia.com/default/topic/572292/-solved-does-gddccontrol-work-for-anyone-here-nvidia-i2c-monitor-display-ddc/#4309293
EndSection
```
This changes the NVIDIA parameter setting on I2C switching and and speed options.

Additionally, add the following code to `/etc/modprobe.d/nvidia-kernel-common.conf` file which is about NVIDIA kernel related Linux modules.
```
options nvidia NVreg_RegistryDwords=RMUseSwI2c=0x01;RMI2cSpeed=100
```