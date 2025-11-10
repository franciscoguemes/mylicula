#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   -h, --help  Display usage information
# Usage          :
#                   ./create_kafka_topics.sh
#                   ./create_kafka_topics.sh -h
# Output stdout  :
#                   - Confirmation messages for topic creation.
#                   - List of created topics in the Kafka instance.
# Output stderr  :
#                   - Error messages if Docker or Kafka commands fail.
# Return code    :
#                   0  if everything runs successfully.
#                   1  if there are errors during execution.
# Description    :
#                   This script connects to the Kafka Docker container named 'broker' and creates
#                   specified Kafka topics. It lists the topics after creation to verify success.
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

Create predefined Kafka topics in the broker Docker container.

OPTIONS:
    -h, --help       Display this help message

DESCRIPTION:
    This script creates Kafka topics in the 'broker' Docker container.
    Topics created:
    - quickstart-events
    - fcd.mt4.accounts

REQUIREMENTS:
    - docker (to interact with Kafka container)
    - Kafka container named 'broker' must be running

EXAMPLES:
    $(basename "$0")          # Create topics
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

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: docker is not installed. Please install Docker:" >&2
    echo "  sudo nala install docker.io" >&2
    exit 1
fi

# Define Kafka container name and topics to create
kafka_container="broker"
topics=(
  "quickstart-events"
  "fcd.mt4.accounts"
)

# Function to check if a Docker container exists
check_container_exists() {
  local container_name="$1"
  if docker ps -a -q -f name="${container_name}" &> /dev/null; then
    return 0
  else
    return 1
  fi
}

# Function to check if a Docker container is running
check_container_running() {
  local container_name="$1"
  if docker ps -q -f name="${container_name}" &> /dev/null; then
    return 0
  else
    return 1
  fi
}

# Function to create Kafka topics
create_kafka_topics() {
  for topic in "${topics[@]}"; do
    echo "Creating topic: ${topic}"
    if ! docker exec --workdir /opt/kafka/bin/ "${kafka_container}" ./kafka-topics.sh --create --topic "${topic}" --bootstrap-server localhost:9092; then
      echo "Failed to create topic: ${topic}" >&2
      exit 1
    fi
  done
}

# Function to list Kafka topics
list_kafka_topics() {
  echo "Listing all topics:"
  if ! docker exec --workdir /opt/kafka/bin/ "${kafka_container}" ./kafka-topics.sh --list --bootstrap-server localhost:9092; then
    echo "Failed to list topics." >&2
    exit 1
  fi
}

# Ensure the Kafka container exists
if ! check_container_exists "${kafka_container}"; then
  echo "Kafka container '${kafka_container}' does not exist. Skipping topic creation." >&2
  exit 0
fi

# Ensure the Kafka container is running
if ! check_container_running "${kafka_container}"; then
  echo "Kafka container '${kafka_container}' is not running. Skipping topic creation." >&2
  exit 0
fi

# Create topics and list them
create_kafka_topics
list_kafka_topics

echo "Kafka topic creation script execution completed."
