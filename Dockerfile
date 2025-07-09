FROM osrf/ros:noetic-desktop-full

# Set bash as the default shell
SHELL ["/bin/bash", "-c"]

# Required libraries
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    cmake \
    git \
    libpoco-dev \
    libeigen3-dev \ 
    lsb-release \
    bash-completion 
    
# libfranka
RUN git clone --recursive https://github.com/frankaemika/libfranka --branch 0.8.0
WORKDIR /libfranka
RUN mkdir build
WORKDIR /libfranka/build
RUN cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=OFF ..
RUN cmake --build .
RUN cpack -G DEB
RUN dpkg -i libfranka*.deb

# ENV CMAKE_PREFIX_PATH="/usr/local:$CMAKE_PREFIX_PATH"

# franka_ros
WORKDIR /catkin_ws
RUN mkdir src
RUN source /opt/ros/noetic/setup.bash && catkin_init_workspace src
RUN git clone --recursive https://github.com/frankaemika/franka_ros src/franka_ros
RUN rosdep install --from-paths src --ignore-src --rosdistro noetic -y --skip-keys libfranka
RUN source /opt/ros/noetic/setup.bash && catkin_make -DCMAKE_BUILD_TYPE=Release -DFranka_DIR:PATH=/libfranka/build

# bashrc: source ROS
# RUN echo "source /ros_entrypoint.bash" >> /root/.bashrc
RUN echo "source /catkin_ws/devel/setup.bash" >> /root/.bashrc

# Pinocchio 
RUN mkdir -p /etc/apt/keyrings
RUN curl http://robotpkg.openrobots.org/packages/debian/robotpkg.asc | tee /etc/apt/keyrings/robotpkg.asc
RUN echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/robotpkg.asc] http://robotpkg.openrobots.org/packages/debian/pub $(lsb_release -cs) robotpkg" | tee /etc/apt/sources.list.d/robotpkg.list
RUN apt-get update
RUN apt-get install -qqy robotpkg-py3*-pinocchio

RUN echo 'export PATH=/opt/openrobots/bin:$PATH' >> /root/.bashrc && \
    echo 'export PKG_CONFIG_PATH=/opt/openrobots/lib/pkgconfig:$PKG_CONFIG_PATH' >> /root/.bashrc && \
    echo 'export LD_LIBRARY_PATH=/opt/openrobots/lib:$LD_LIBRARY_PATH' >> /root/.bashrc && \
    echo 'export PYTHONPATH=/opt/openrobots/lib/python3.8/site-packages:$PYTHONPATH' >> /root/.bashrc && \
    echo 'export CMAKE_PREFIX_PATH=/opt/openrobots:$CMAKE_PREFIX_PATH' >> /root/.bashrc

# ruckig
RUN git clone --recursive https://github.com/pantor/ruckig.git /ruckig
WORKDIR /ruckig 
RUN mkdir build 
WORKDIR /ruckig/build 
RUN cmake -DCMAKE_BUILD_TYPE=Release ..
RUN make
RUN make install
    
# matlogger2
RUN git clone --recursive https://github.com/ADVRHumanoids/MatLogger2.git /MatLogger2
WORKDIR /MatLogger2 
RUN mkdir build 
WORKDIR /MatLogger2/build 
RUN cmake ..
RUN make
RUN make install

RUN apt-get update && apt-get install -y \
	libmatio-dev \
	libhdf5-dev 

WORKDIR /catkin_ws

RUN source /root/.bashrc
CMD ["bash", "--login"]
