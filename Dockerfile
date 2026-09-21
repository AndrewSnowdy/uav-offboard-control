FROM ros:humble-ros-base-jammy

ENV DEBIAN_FRONTEND=noninteractive

# Core build tools and Foxglove
RUN apt-get update && apt-get install -y \
    cmake \
    build-essential \
    git \
    python3-colcon-common-extensions \
    python3-pip \
    ros-humble-foxglove-bridge \
    ros-humble-eigen3-cmake-module \
    && rm -rf /var/lib/apt/lists/*

# Compile Micro XRCE-DDS Agent
RUN git clone -b v2.4.3 https://github.com/eProsima/Micro-XRCE-DDS-Agent.git /tmp/uxrce_agent && \
    cd /tmp/uxrce_agent && \
    mkdir build && cd build && \
    cmake .. && make -j$(nproc) && make install && \
    ldconfig /usr/local/lib/ && \
    rm -rf /tmp/uxrce_agent

# Pre-compile px4_msgs and px4_ros_com into an underlay workspace
RUN mkdir -p /opt/px4_underlay_ws/src && \
    cd /opt/px4_underlay_ws/src && \
    git clone https://github.com/PX4/px4_msgs.git && \
    git clone https://github.com/PX4/px4_ros_com.git && \
    cd /opt/px4_underlay_ws && \
    . /opt/ros/humble/setup.sh && \
    colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release

WORKDIR /root/uav_ws

# Chain the underlay environment so custom_navigation finds px4_msgs automatically
RUN echo "source /opt/ros/humble/setup.bash" >> /root/.bashrc && \
    echo "source /opt/px4_underlay_ws/install/setup.bash" >> /root/.bashrc && \
    echo "if [ -f /root/uav_ws/install/setup.bash ]; then source /root/uav_ws/install/setup.bash; fi" >> /root/.bashrc

CMD ["/bin/bash"]
