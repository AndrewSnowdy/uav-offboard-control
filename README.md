Modular ROS 2 offboard navigation and control framework interfacing with the PX4 Autopilot flight stack via the Micro XRCE-DDS middleware bridge.

---

## 1. System Architecture

The setup separates host simulation/hardware execution from containerized autonomy logic:

- **Host (Ubuntu 24.04)**: Runs `PX4-Autopilot` SITL + Gazebo Harmonic (GPU-accelerated native rendering).
- **Container (Docker / ROS 2 Humble)**: Runs `MicroXRCEAgent`, `px4_msgs`, and `custom_navigation`.
- **Flight Hardware**: The container runs directly on the companion computer (e.g. Jetson / Pi) with the agent attached via serial UART.
