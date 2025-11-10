#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   $@  Names of one or more containers (e.g., some-rabbit redis_alpine_3_20)
#                   -h, --help  Display usage information
# Usage          :
#                   ./recreate_docker_container.sh some-rabbit redis_alpine_3_20
#                   ./recreate_docker_container.sh -h
# Output stdout  :
#                   - Messages confirming the stopping, removing, and recreation of containers.
# Output stderr  :
#                   - Error message if Docker is not installed or if there are issues with Docker commands.
# Return code    :
#                   0  if everything runs successfully.
#                   1  if Docker is not installed or if there are errors during execution.
# Description	:
#                   This script stops, removes, and recreates one or more Docker containers.
#                   The containers are recreated based on specific commands for known containers.
#                   If a container name is not recognized, an error will be shown.
# Author       	: Francisco Güemes
# Email         	: francisco@franciscoguemes.com
# See also	    : https://stackoverflow.com/questions/14008125/shell-script-common-template
#                 https://devhints.io/bash
#                 https://linuxhint.com/30_bash_script_examples/
#                 https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
####################################################################################################

# Function to display help
show_help() {
    cat << EOF
Usage: $(basename "$0") CONTAINER_NAME [CONTAINER_NAME...] [-h|--help]

Recreate Docker containers by stopping, removing, and creating them fresh.

OPTIONS:
    CONTAINER_NAME   One or more container names to recreate
    -h, --help       Display this help message

DESCRIPTION:
    This script recreates Docker containers from scratch by:
    1. Stopping the container if running
    2. Removing the container
    3. Creating it again with predefined configuration

SUPPORTED CONTAINERS:
    some-rabbit          RabbitMQ message broker
    redis_alpine_3_20    Redis cache
    broker               Apache Kafka

REQUIREMENTS:
    - docker

EXAMPLES:
    $(basename "$0") some-rabbit              # Recreate RabbitMQ
    $(basename "$0") some-rabbit broker       # Recreate RabbitMQ and Kafka
    $(basename "$0") --help                   # Show this help

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>
EOF
}

# Function to check if a command is available on the system
check_command() {
  local cmd="$1"
  if command -v "${cmd}" &> /dev/null; then
    return 0
  else
    return 1
  fi
}

# Function to stop and remove a Docker container
stop_and_remove_container() {
  local container_name="$1"

  # Stop container if it is running
  if [ "$(docker ps -q -f name=${container_name})" ]; then
    echo "Stopping container '${container_name}'..."
    docker stop "${container_name}"
    echo "Container '${container_name}' stopped."
  fi

  # Remove the container if it exists
  if [ "$(docker ps -a -q -f name=${container_name})" ]; then
    echo "Removing container '${container_name}'..."
    docker rm "${container_name}"
    echo "Container '${container_name}' removed."
  fi
}

# Function to recreate a Docker container based on its name
recreate_container() {
  local container_name="$1"

  case "$container_name" in
    some-rabbit)
      echo "Recreating RabbitMQ container '${container_name}'..."
      docker run -d -p5672:5672 -p15672:15672 --hostname my-rabbit --name "${container_name}" rabbitmq:3.13.4-management
      ;;
    redis_alpine_3_20)
      echo "Recreating Redis container '${container_name}'..."
      docker run --name "${container_name}" -d -p6379:6379 redis:alpine3.20
      ;;
    broker)
      echo "Recreating Kafka container '${container_name}'..."
      docker run -d --name "${container_name}" -p 9092:9092 apache/kafka:3.8.0
      ;;
    *)
      echo "Error: Unknown container name '${container_name}'. No instructions for recreation."
      return 1
      ;;
  esac
}

# Check for help flag
if [ "$#" -eq 1 ]; then
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
  esac
fi

# Check if Docker is installed
if ! check_command "docker"; then
  echo "Error: docker is not installed. Please install Docker:" >&2
  echo "  sudo nala install docker.io" >&2
  echo "  sudo systemctl start docker" >&2
  echo "  sudo usermod -aG docker \$USER  # Then log out and back in" >&2
  exit 1
fi

# Ensure that at least one container name is passed
if [ "$#" -eq 0 ]; then
  echo "Error: No container names provided" >&2
  show_help
  exit 1
fi

# Iterate over all provided container names
for container_name in "$@"; do
  # Skip help flags in arguments
  case "$container_name" in
    -h|--help)
      show_help
      exit 0
      ;;
  esac
  echo "Processing container '${container_name}'..."

  # Stop and remove the container
  stop_and_remove_container "${container_name}"

  # Recreate the container
  recreate_container "${container_name}"
done

echo "All specified containers have been recreated."
