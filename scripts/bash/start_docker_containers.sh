#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   -h, --help  Display usage information
# Usage          :
#                   ./start_docker_containers.sh
#                   ./start_docker_containers.sh -h
# Output stdout  :
#                   - Confirmation messages for Docker and container existence checks.
#                   - Messages indicating whether containers are being created or started.
# Output stderr  :
#                   - Error message if Docker is not installed.
#                   - Error messages if there are issues with Docker commands.
# Return code    :
#                   0  if everything runs successfully.
#                   1  if Docker is not installed or if there are errors during execution.
# Description	:
#                   This script checks if Docker is installed on the system. If Docker is installed,
#                   it verifies the existence of specific Docker containers: 'some-rabbit',
#                   'redis_alpine_3_20', and 'broker' (Kafka). If any container does not exist, the script
#                   creates them using the specified Docker run commands. The script then opens a new
#                   terminal window, sets the terminal title to 'docker', starts the containers, and
#                   executes `docker ps` to show the status of all running containers.
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
Usage: $(basename "$0") [-h|--help]

Start development Docker containers (RabbitMQ, Redis, Kafka).

OPTIONS:
    -h, --help       Display this help message

DESCRIPTION:
    This script manages three Docker containers for local development:
    - RabbitMQ (some-rabbit): Message broker on ports 5672, 15672
    - Redis (redis_alpine_3_20): Cache on port 6379
    - Kafka (broker): Message streaming on port 9092

    The script will:
    1. Check if Docker is installed
    2. Create containers if they don't exist
    3. Start containers in a new terminal window

CONTAINERS:
    RabbitMQ:  some-rabbit (rabbitmq:3.13.4-management)
    Redis:     redis_alpine_3_20 (redis:alpine3.20)
    Kafka:     broker (apache/kafka:3.8.0)

REQUIREMENTS:
    - docker
    - gnome-terminal or xfce4-terminal
    - create_kafka_topics.sh (for Kafka setup)

EXAMPLES:
    $(basename "$0")          # Start all containers
    $(basename "$0") --help   # Show this help

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>
EOF
}

# Parse arguments
if [ "$#" -eq 1 ]; then
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Error: Unknown argument '$1'" >&2
            show_help
            exit 1
            ;;
    esac
elif [ "$#" -gt 1 ]; then
    echo "Error: Too many arguments." >&2
    show_help
    exit 1
fi

# Define container names and their respective run commands
rabbitmq_container="some-rabbit"
rabbitmq_run_command="docker run -d -p5672:5672 -p15672:15672 --hostname my-rabbit --name ${rabbitmq_container} rabbitmq:3.13.4-management"

redis_container="redis_alpine_3_20"
redis_run_command="docker run --name ${redis_container} -d -p6379:6379 redis:alpine3.20"

kafka_container="broker"
kafka_run_command="docker run -d --name ${kafka_container} -p 9092:9092 apache/kafka:3.8.0"

# Function to check if a command is available on the system
check_command() {
  local cmd="$1"
  if command -v "${cmd}" &> /dev/null; then
    return 0
  else
    return 1
  fi
}

# Function to check if a Docker container exists, and create it if it doesn't
check_and_create_container() {
  local container_name="$1"
  local run_command="$2"

  if [ ! "$(docker ps -a -q -f name=${container_name})" ]; then
    echo "Container '${container_name}' not found. Creating it..."
    eval "${run_command}"
    if [[ "${container_name}" == "${kafka_container}" ]];then
      # The script create_kafka_topics.sh must be installed in the system for this to work fine
      create_kafka_topics.sh
    fi
  else
    echo "Container '${container_name}' already exists."
  fi
}

# Check if Docker is installed
if ! check_command "docker"; then
  echo "Error: docker is not installed. Please install Docker:" >&2
  echo "  sudo nala install docker.io" >&2
  echo "  sudo systemctl start docker" >&2
  echo "  sudo usermod -aG docker \$USER  # Then log out and back in" >&2
  exit 1
fi


# Check and create containers if they don't exist
check_and_create_container "${rabbitmq_container}" "${rabbitmq_run_command}"
check_and_create_container "${redis_container}" "${redis_run_command}"
check_and_create_container "${kafka_container}" "${kafka_run_command}"


# Determine the terminal emulator to use
if check_command "xfce4-terminal"; then
  terminal_cmd="xfce4-terminal --title='docker' --command='bash -c \"docker start ${rabbitmq_container} ${redis_container} ${kafka_container}; docker ps; exec bash\"'"
elif check_command "gnome-terminal"; then
  terminal_cmd="gnome-terminal --title='docker' -- bash -c 'docker start ${rabbitmq_container} ${redis_container} ${kafka_container}; docker ps; exec bash'"
else
  echo "Neither XFCE Terminal nor GNOME Terminal is installed. Please install one of these and try again." >&2
  exit 1
fi

# Open a new terminal window and start the containers
eval "${terminal_cmd}" &

echo "Script execution completed."
