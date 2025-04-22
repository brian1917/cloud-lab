#!/bin/bash

# Check if a config file is provided as an argument
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <config_file>"
  exit 1
fi

# Load the config file
CONFIG_FILE="$1"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Config file not found: $CONFIG_FILE"
  exit 1
fi

# Source the config file
source "$CONFIG_FILE"

# Ensure required variables are set
REQUIRED_VARS=("API_URL" "NAME" "DELETE_PWD")
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    echo "Error: $var must be defined in the config file."
    exit 1
  fi
done

# Create the simplified JSON payload
json_payload=$(cat <<EOF
{
  "name": "$NAME",
  "delete_pwd": "$DELETE_PWD"
}
EOF
)

# Debug: Log the JSON payload
echo "JSON payload saved to delete_payload.json"
echo "$json_payload" > delete_payload.json

# Send the DELETE request
response=$(curl -s -w "%{http_code}" -o response_body.txt -X DELETE "$API_URL" \
    -H "Content-Type: application/json" \
    -d "$json_payload")

# Debug: Log the response body
echo "Response body:"
cat response_body.txt

# Check the response status
if [ "$response" -eq 200 ]; then
  echo "Successfully deleted the instance."
else
  echo "Failed to delete the instance (HTTP status: $response)"
fi