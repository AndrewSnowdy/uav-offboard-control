# Host Prerequisites

Clone PX4-Autopilot and run their script to instal Gazebo.
``` bash
cd ~
git clone https://github.com/PX4/PX4-Autopilot.git --recursive
cd ~/PX4-Autopilot
bash ./Tools/setup/ubuntu.sh
```

install docker: https://docs.docker.com/engine/install/ubuntu/

install foxglove: 
https://foxglove.dev/download

Clone this repo.
``` bash

```

# UAV Offboard Control Stack (PX4 + ROS 2)

Modular ROS 2 offboard navigation and control framework interfacing with the PX4 Autopilot flight stack via the Micro XRCE-DDS middleware bridge.

---

## 1. System Architecture

The environment enforces a split-host model:
* **Host (Ubuntu 24.04 LTS)**: Runs **PX4 SITL** and **Gazebo Harmonic** natively for full GPU hardware acceleration without display/X11 container pass-through overhead.
* **Host Visualization**: Runs **Foxglove Studio** natively via APT, eliminating the need to install ROS 2 on the host system.
* **Companion Environment (Docker / Ubuntu 22.04)**: Runs **ROS 2 Humble**, **Micro XRCE-DDS Agent**, `foxglove_bridge`, `px4_msgs`, and `custom_navigation`.
* **Flight Hardware**: The same Docker container runs on the physical companion computer (e.g., Jetson / Pi) with the agent attached via serial UART.
