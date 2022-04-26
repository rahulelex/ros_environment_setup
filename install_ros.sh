#! /bin/sh
Code=$(cat /etc/lsb-release | grep -oP "^DISTRIB_CODENAME=\K.*")
remove_ros() {
    sudo dpkg --configure -a
    echo "########## Removing instances of ROS if previously installed ##########"
    sudo apt-get update
    sudo apt-get remove ros-* -y
    sudo apt-get purge ros-* -y
    echo "########## Removing of old instances of ROS : DONE ##########"
}
install_ros() {
    echo "########## Installing ROS for distro: $1 ##########"
    sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
    sudo apt install curl -y # if you haven't already installed curl
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
    sudo apt update
    sudo apt install ros-$1-desktop-full -y
}
setup_env() {
    nmcli -t -f DEVICE,TYPE device | cut -f1 -d":"
    echo "Enter your device type to setup IP in bashrc"
    read device_type
    echo "source /opt/ros/$1/setup.bash" >> ~/.bashrc
    echo "value="$(ip a s $device_type | egrep -o 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d' ' -f2)"" >> ~/.bashrc
    echo "export ROS_MASTER_URI=http://$value:11311" >> ~/.bashrc
    echo "export ROS_HOSTNAME=$value" >> ~/.bashrc
    echo "export ROS_IP=$value" >> ~/.bashrc
    . ~/.bashrc
}
ros_deps() {
    sudo apt install $1-rosdep $1-rosinstall $1-rosinstall-generator $1-wstool build-essential -y
    sudo apt install $1-rosdep
    sudo rosdep init
    rosdep update
}
script() {
while :
	do 
	    echo "Please select operation to perform"
	    echo "1. Remove already installed ROS"
	    echo "2. Install ROS for $1"
	    echo "3. Setup environment"
	    echo "4. Exit"
	    read operation
	    case $operation in
			"1")
				remove_ros
			;;
			"2")
				install_ros $1
				;;
			"3")
				setup_env $1
				ros_deps $2
				sudo apt-get autoremove -y
				echo "REBOOT your system"
			;;
			"4")
				break
			;;
		esac
	done
}
case  $1  in
    "melodic")
    if [ "$Code" = "bionic" ] || [ "$Code" = "artful" ]
    then
		script melodic python
    else
        echo "Ubuntu $Code does not support ROS melodic"
    fi
    ;;
    "neotic")
        if [ "$Code" = "focal" ]
        then
			script neotic python3
            echo "REBOOT your system"
        else
            echo "Ubuntu $Code does not support ROS Noetic"
        fi
    ;;            
    *)
    echo "Bad argument!"
    echo "########## Usage: sh install_ros.sh argument1 ##########"
    echo "########## This script can not install for $1 ##########"
    ;;            
esac 
