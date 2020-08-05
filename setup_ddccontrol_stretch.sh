#! /bin/sh

# Checking OS and Architecture.
DEBIAN_NAME=$(cat /etc/*-release | grep -Po 'ID=\K([^"]*)')
DEBIAN_VERSION=$(cat /etc/*-release | grep -Po 'VERSION_CODENAME=\K([^"]*)')
if [ $DEBIAN_NAME != "debian" ] || [ $DEBIAN_VERSION != "stretch" ]
then
	echo "[INFO] The setup.sh is only exclusive to Debian9 \"Stretch\" GNU/Linux."
	exit 1
fi

# Installing kernel headers for the drivers to build with.
echo "\n[INFO] Installing linux-headers-"$(uname -r)"..."
if [ $(uname -m)=="x86_64" ] || [ $(uname -m)=="x86" ]
then
	apt install linux-headers-$(uname -r) -y
	if [ $? != 0 ]
	then
		echo "[FAIL] Unable to download and install:\n\tplease check if your Debian is connected to the Internet."
		exit 1
	fi
fi

# Changing repository in "/etc/apt/sources.list".
# REFERENCE: https://wiki.debian.org/NvidiaGraphicsDrivers
echo "\n[INFO] Changing repository."
if grep -Fq "http://deb.debian.org/debian/" /etc/apt/sources.list
then
	sed -i 's/http:\/\/deb.debian.org\/debian\/ '$DEBIAN_VERSION' main.*/http:\/\/deb.debian.org\/debian\/ '$DEBIAN_VERSION' main contrib non-free/' /etc/apt/sources.list
else
	echo "\nhttp://deb.debian.org/debian/ "$DEBIAN_VERSION" main contrib non-free" >> /etc/apt/sources.list
fi
apt update

# Install nvidia-driver package.
echo "\n[INFO] Installing nvidia-driver v390 package."
# apt install nvidia-smi
# NVIDIA_DRIVER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)
# echo $?
# if [ $? -eq 127 ]
# then
# 	# apt-get --purge remove "*nvidia* -y"
# fi
if [ $DEBIAN_VERSION = "stretch" ]
then
	apt install nvidia-driver -y
#elif [ $DEBIAN_VERSION = "buster" ]
#	apt install nvidia-legacy-390xx-driver -y
fi

# Configure kernel and nvidia parameters.
echo "\n[INFO] Configure nvidia.conf copied to '/etc/X11'"
cp -a /usr/share/X11/xorg.conf.d/ /etc/X11
touch /etc/X11/xorg.conf.d/90-nvidia_i2c.conf
echo 'Section "Device"
    Driver\t"nvidia"
    Identifier\t"Dev0"
    Option	"RegistryDwords" "RMUseSwI2c=0x01; RMI2cSpeed=100"
    # solves problem of i2c errors with nvidia driver
    # per https://devtalk.nvidia.com/default/topic/572292/-solved-does-gddccontrol-work-for-anyone-here-nvidia-i2c-monitor-display-ddc/#4309293
EndSection' > /etc/X11/xorg.conf.d/90-nvidia_i2c.conf
echo '\noptions nvidia NVreg_RegistryDwords=RMUseSwI2c=0x01;RMI2cSpeed=100' >> /etc/modprobe.d/nvidia-kernel-common.conf

# Install required packages for ddccontrol.
echo "\n[INFO] Installing required packages for DDC/CI."
apt install i2c-tools libcanberra-gtk-module git intltool libxml2-dev libpci-dev libgtk2.0-dev -y
adduser $USER i2c
/bin/sh -c 'echo i2c-dev >> /etc/modules'

# Install ddccontrol.
echo "\n[INFO] Installing DDC/CI package."
git clone https://github.com/ddccontrol/ddccontrol.git
cd ddccontrol
./autogen.sh
./configure --prefix=/usr/ --sysconfdir=/etc --libexecdir=/usr/lib
make -j4
make install
cd ..

git clone https://github.com/ddccontrol/ddccontrol-db
cd ddccontrol-db
./autogen.sh 
./configure --prefix=/usr/
make -j4
make install
cd ..

chmod -R 777 ./ddccontrol
chmod -R 777 ./ddccontrol-db
apt install gddccontrol -y
ldconfig

reboot