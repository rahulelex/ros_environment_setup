#! /bin/sh
#
#
#

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
    echo "source /opt/ros/$1/setup.bash" >> ~/.bashrc
    echo "value="$(ip a s wlp2s0 | egrep -o 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d' ' -f2)"" >> ~/.bashrc
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
case  $1  in
    "melodic")
    if [ "$Code" = "bionic" ] || [ "$Code" = "artful" ]
    then
        remove_ros
        install_ros melodic
        setup_env melodic
        ros_deps python
        sudo apt-get autoremove -y
        echo "REBOOT your system"
    else
        echo "Ubuntu $Code does not support ROS melodic"
    fi
    ;;
    "neotic")
        if [ "$Code" = "focal" ]
        then
            remove_ros
            install_ros neotic
            setup_env neotic
            ros_deps python3
            sudo apt-get autoremove -y
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
