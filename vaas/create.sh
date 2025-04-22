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
REQUIRED_VARS=("API_URL" "NAME" "EMAIL" "OWNER_FIRST_NAME" "OWNER_LAST_NAME" "DELETE_PWD" "MANAGEMENT_SERVER" "USER" "PASSWORD" "ORG" "SKIP_WORKLOADER" "SOUTHBOUND_API_VERSION" "CLEAR_EXISTING_POLICY_OBJECTS" "UNPAIR_EXISTING_VENS")
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    echo "Error: $var must be defined in the config file."
    exit 1
  fi
done

# Initialize the files section of the JSON payload
files_section=""

# Check if CSV_DIR is set and process CSV files if it exists
if [ -n "$CSV_DIR" ] && [ -d "$CSV_DIR" ]; then
  # Detect the operating system
  OS_TYPE=$(uname)

  # Loop through each CSV file in the directory
  for csv_file in "$CSV_DIR"/*.csv; do
    # Get the base name of the file (e.g., adgroups.csv)
    file_name=$(basename "$csv_file")

    # Base64 encode the file based on the OS
    if [ "$OS_TYPE" = "Darwin" ]; then
      # macOS
      encoded_content=$(base64 -i "$csv_file")
    else
      # Linux
      encoded_content=$(base64 -w 0 "$csv_file")
    fi

    # Append the file entry to the files section
    files_section+=$(cat <<EOF
    "$file_name": "$encoded_content",
EOF
)
  done

  # Remove the trailing comma from the files section
  files_section=${files_section%,}
fi

# Create the full JSON payload
json_payload=$(cat <<EOF
{
  "name": "$NAME",
  "email": "$EMAIL",
  "owner_first_name": "$OWNER_FIRST_NAME",
  "owner_last_name": "$OWNER_LAST_NAME",
  "delete_pwd": "$DELETE_PWD",
  "management_server": "$MANAGEMENT_SERVER",
  "user": "$USER",
  "password": "$PASSWORD",
  "org": "$ORG",
  "skip_workloader": $SKIP_WORKLOADER,
  "southbound_api_version": $SOUTHBOUND_API_VERSION,
  "clear_existing_policy_objects": $CLEAR_EXISTING_POLICY_OBJECTS,
  "unpair_existing_vens": $UNPAIR_EXISTING_VENS
EOF
)

# Add the files section if it exists
if [ -n "$files_section" ]; then
  json_payload+=$(cat <<EOF
,
  "files": {
    $files_section
  }
EOF
)
fi

# Close the JSON payload
json_payload+=$(cat <<EOF
}
EOF
)

# Debug: Log the full JSON payload
echo "Full JSON payload saved to create_payload.json"
echo "$json_payload" > create_payload.json

# Send the POST request
response=$(curl -s -w "%{http_code}" -o response_body.txt -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    --data-binary @create_payload.json)

# Debug: Log the response body
echo "Response body:"
cat response_body.txt

# Check the response status
if [ "$response" -eq 201 ]; then
  echo "Successfully created a new instance with all CSV files."
else
  echo "Failed to create a new instance (HTTP status: $response)"
fi
