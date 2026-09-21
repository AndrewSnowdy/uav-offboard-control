IMAGE_NAME ?= uav-offboard:humble
CONTAINER_NAME ?= uav_offboard_dev
WORKSPACE_DIR := $(shell pwd)

PX4_DIR ?= PX4-autopilot
PX4_VERSION ?= v1.17.0
PX4_MODEL ?= gz_x500
PX4_WORLD ?= pillars

.PHONY: help build run exec build-ros clean setup-sim run-sim clean-sim

help:
	@echo "Available targets:"
	@echo "  make build       - Build the Docker development image"
	@echo "  make run         - Run the container interactively with volume mount"
	@echo "  make exec        - Open a secondary terminal inside the running container"
	@echo "  make build-ros   - Compile the ROS 2 workspace inside the container"
	@echo "  make setup-sim   - Clone PX4-Autopilot, install host dependencies, and build SITL bridges"
	@echo "  make run-sim     - Launch PX4 SITL and Gazebo with the custom pillars world"
	@echo "  make clean-sim   - Remove compiled PX4 build artifacts"
	@echo "  make clean       - Remove ROS 2 build, install, and log directories"

# ---------------------------------------------------------
# Simulation (Host PC Targets)
# ---------------------------------------------------------

setup-sim:
	@echo "==> 1. Checking / Cloning PX4-Autopilot ($(PX4_VERSION))..."
	@if [ ! -d "$(PX4_DIR)" ]; then \
		git clone --depth 1 --branch $(PX4_VERSION) --recursive https://github.com/PX4/PX4-Autopilot.git $(PX4_DIR); \
	else \
		echo "PX4 directory already exists at $(PX4_DIR), skipping clone."; \
	fi
	@echo "==> 2. Installing PX4 SITL & Gazebo host dependencies..."
	@cd $(PX4_DIR) && bash Tools/setup/ubuntu.sh --no-nuttx
	@echo "==> SimulatVion setup complete. You can now run 'make run-sim'."

run-sim:
	@echo "==> Launching PX4 SITL with model '$(PX4_MODEL)' and world '$(PX4_WORLD)'..."
	@export GZ_SIM_RESOURCE_PATH="$(WORKSPACE_DIR)/simulation/models:$(WORKSPACE_DIR)/simulation/worlds:$${GZ_SIM_RESOURCE_PATH}"; \
	export PX4_GZ_WORLD="$(PX4_WORLD)"; \
	cd $(PX4_DIR) && make px4_sitl $(PX4_MODEL)

clean-sim:
	@echo "==> Cleaning PX4 build directory..."
	@if [ -d "$(PX4_DIR)" ]; then \
		cd $(PX4_DIR) && make clean; \
	fi

# ---------------------------------------------------------
# Flight Software & Docker Targets
# ---------------------------------------------------------

build:
	docker build -t $(IMAGE_NAME) -f flight_software/Dockerfile flight_software

run:
	docker run -it --rm \
		--name $(CONTAINER_NAME) \
		--net=host \
		--ipc=host \
		--privileged \
		-v $(WORKSPACE_DIR)/flight_software:/root/uav_ws \
		$(IMAGE_NAME) bash

exec:
	docker exec -it $(CONTAINER_NAME) bash

build-ros:
	docker run --rm \
		--net=host \
		-v $(WORKSPACE_DIR)/flight_software:/root/uav_ws \
		$(IMAGE_NAME) bash -c "source /opt/ros/humble/setup.bash && if [ -f /opt/px4_underlay_ws/install/setup.bash ]; then source /opt/px4_underlay_ws/install/setup.bash; fi && cd /root/uav_ws && colcon build --symlink-install"

clean:
	rm -rf flight_software/build flight_software/install flight_software/log
