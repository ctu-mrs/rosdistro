FROM ctumrs/ros:noetic

RUN apt-get -y update

# workaround interractive prompts during apt installations
RUN echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install keyboard-configuration

RUN apt-get -y install software-properties-common curl bash

RUN curl https://ctu-mrs.github.io/ppa-stable/add_ppa.sh | bash

RUN apt-get -y install ros-noetic-catkin python3-catkin-tools fakeroot debhelper python3-pip dpkg-dev

RUN pip3 install -U bloom gitman
