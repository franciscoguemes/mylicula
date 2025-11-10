#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   -d, --delete  Delete containers after stopping them
#                   -h, --help    Display usage information
# Usage          :
#                   ./stop_docker_containers.sh
#                   ./stop_docker_containers.sh -d
#                   ./stop_docker_containers.sh --help
# Output stdout  :
#                   - Confirmation messages for Docker and container stopping.
#                   - Messages indicating whether containers are being removed.
# Output stderr  :
#                   - Error message if Docker is not installed.
#                   - Error messages if there are issues with Docker commands.
# Return code    :
#                   0  if everything runs successfully.
#                   1  if Docker is not installed or if there are errors during execution.
# Description	:
#                   This script checks if Docker is installed on the system. If Docker is installed,
#                   it stops and optionally removes specific Docker containers: 'some-rabbit',
#                   'redis_alpine_3_20', and 'broker' (Kafka). The script opens a new terminal window,
#                   sets the terminal title to 'docker', and then executes `docker ps` to show the
#                   status of all running containers.
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
Usage: $(basename "$0") [-d|--delete] [-h|--help]

Stop development Docker containers (RabbitMQ, Redis, Kafka).

OPTIONS:
    -d, --delete     Remove containers after stopping them
    -h, --help       Display this help message

DESCRIPTION:
    This script stops three Docker containers used for local development:
    - RabbitMQ (some-rabbit)
    - Redis (redis_alpine_3_20)
    - Kafka (broker)

    By default, containers are only stopped. Use -d/--delete to remove them.

CONTAINERS:
    RabbitMQ:  some-rabbit
    Redis:     redis_alpine_3_20
    Kafka:     broker

REQUIREMENTS:
    - docker
    - gnome-terminal or xfce4-terminal

EXAMPLES:
    $(basename "$0")           # Stop containers
    $(basename "$0") -d        # Stop and remove containers
    $(basename "$0") --help    # Show this help

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>
EOF
}

# Define container names
rabbitmq_container="some-rabbit"
redis_container="redis_alpine_3_20"
kafka_container="broker"

# Function to check if a command is available on the system
check_command() {
  local cmd="$1"
  if command -v "${cmd}" &> /dev/null; then
    return 0
  else
    return 1
  fi
}

# Function to stop and optionally remove a Docker container
stop_and_remove_container() {
  local container_name="$1"
  local remove_container="$2"

  if [ "$(docker ps -q -f name=${container_name})" ]; then
    echo "Stopping container '${container_name}'..."
    docker stop "${container_name}"
    echo "Container '${container_name}' stopped."
  else
    echo "Container '${container_name}' is not running."
  fi

  if [ "$remove_container" = "true" ]; then
    if [ "$(docker ps -a -q -f name=${container_name})" ]; then
      echo "Removing container '${container_name}'..."
      docker rm "${container_name}"
      echo "Container '${container_name}' removed."
    else
      echo "Container '${container_name}' does not exist."
    fi
  fi
}

# Parse command-line arguments
delete_containers="false"
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -d|--delete) delete_containers="true"; shift ;;
    -h|--help) show_help; exit 0 ;;
    *) echo "Error: Unknown option: $1" >&2; show_help; exit 1 ;;
  esac
done

# Check if Docker is installed
if ! check_command "docker"; then
  echo "Error: docker is not installed. Please install Docker:" >&2
  echo "  sudo nala install docker.io" >&2
  echo "  sudo systemctl start docker" >&2
  echo "  sudo usermod -aG docker \$USER  # Then log out and back in" >&2
  exit 1
fi

# Stop and optionally remove containers
stop_and_remove_container "${rabbitmq_container}" "${delete_containers}"
stop_and_remove_container "${redis_container}" "${delete_containers}"
stop_and_remove_container "${kafka_container}" "${delete_containers}"

# Determine the terminal emulator to use
if check_command "xfce4-terminal"; then
  terminal_cmd="xfce4-terminal --title='docker' --command='bash -c \"docker ps; exec bash\"'"
elif check_command "gnome-terminal"; then
  terminal_cmd="gnome-terminal --title='docker' -- bash -c 'docker ps; exec bash'"
else
  echo "Neither XFCE Terminal nor GNOME Terminal is installed. Please install one of these and try again." >&2
  exit 1
fi

# Open a new terminal window and show the Docker status
eval "${terminal_cmd}" &

echo "Script execution completed."
