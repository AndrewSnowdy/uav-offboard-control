#!/usr/bin/env python3
import rclpy
from rclpy.node import Node
from rclpy.qos import QoSProfile, ReliabilityPolicy, HistoryPolicy, DurabilityPolicy

from px4_msgs.msg import OffboardControlMode, TrajectorySetpoint, VehicleCommand, VehicleOdometry

class OffboardTakeoff(Node):
    def __init__(self):
        super().__init__('offboard_takeoff')

        # PX4 uORB over DDS requires Best Effort QoS
        qos_profile = QoSProfile(
            reliability=ReliabilityPolicy.BEST_EFFORT,
            durability=DurabilityPolicy.VOLATILE,
            history=HistoryPolicy.KEEP_LAST,
            depth=1
        )

        # Publishers
        self.ocm_pub = self.create_publisher(OffboardControlMode, '/fmu/in/offboard_control_mode', qos_profile)
        self.sp_pub = self.create_publisher(TrajectorySetpoint, '/fmu/in/trajectory_setpoint', qos_profile)
        self.cmd_pub = self.create_publisher(VehicleCommand, '/fmu/in/vehicle_command', qos_profile)

        # Odometry Subscriber
        self.odom_sub = self.create_subscription(VehicleOdometry, '/fmu/out/vehicle_odometry', self.odom_callback, qos_profile)

        self.current_pos = [0.0, 0.0, 0.0]
        self.counter = 0
        self.armed = False
        self.offboard_engaged = False

        # 20 Hz control loop
        self.timer = self.create_timer(0.05, self.timer_callback)
        self.get_logger().info("Offboard Takeoff Node Initialized")

    def odom_callback(self, msg: VehicleOdometry):
        self.current_pos = list(msg.position)

    def timer_callback(self):
        # 1. Publish OffboardControlMode heartbeat (position + velocity enabled)
        ocm = OffboardControlMode()
        ocm.timestamp = int(self.get_clock().now().nanoseconds / 1000)
        ocm.position = True
        ocm.velocity = False
        ocm.acceleration = False
        ocm.attitude = False
        ocm.body_rate = False
        self.ocm_pub.publish(ocm)

        # 2. Publish target setpoint: 3 meters altitude (NED frame: Z = -3.0m)
        sp = TrajectorySetpoint()
        sp.timestamp = int(self.get_clock().now().nanoseconds / 1000)
        sp.position = [0.0, 0.0, -3.0]
        sp.yaw = 0.0  # Face North
        self.sp_pub.publish(sp)

        # 3. After 10 cycles (~0.5s of streaming), request Offboard mode and Arm
        if self.counter == 10:
            self.engage_offboard_mode()
            self.arm()

        self.counter += 1

    def arm(self):
        self.send_vehicle_command(VehicleCommand.VEHICLE_CMD_COMPONENT_ARM_DISARM, param1=1.0)
        self.get_logger().info("Arm command sent")

    def engage_offboard_mode(self):
        # param1 = 1 (custom mode), param2 = 6 (PX4 Offboard submode)
        self.send_vehicle_command(VehicleCommand.VEHICLE_CMD_DO_SET_MODE, param1=1.0, param2=6.0)
        self.get_logger().info("Offboard mode request sent")

    def send_vehicle_command(self, command, param1=0.0, param2=0.0):
        cmd = VehicleCommand()
        cmd.timestamp = int(self.get_clock().now().nanoseconds / 1000)
        cmd.param1 = float(param1)
        cmd.param2 = float(param2)
        cmd.command = command
        cmd.target_system = 1
        cmd.target_component = 1
        cmd.source_system = 1
        cmd.source_component = 1
        cmd.from_external = True
        self.cmd_pub.publish(cmd)

def main(args=None):
    rclpy.init(args=args)
    node = OffboardTakeoff()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()

if __name__ == '__main__':
    main()
