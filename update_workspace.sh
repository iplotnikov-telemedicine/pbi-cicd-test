#!/bin/bash

# Get access token
token_response=$(curl --location 'https://login.microsoftonline.com/'"$TENANT_ID"'/oauth2/v2.0/token' \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'client_id='"$CLIENT_ID"'' \
    --data-urlencode 'scope=https://api.fabric.microsoft.com/.default' \
    --data-urlencode 'client_secret='"$CLIENT_SECRET"'' \
    --data-urlencode 'grant_type=client_credentials')

access_token=$(echo "$token_response" | grep -o '"access_token":"[^"]*' | awk -F'"' '{print $4}')

# Get status of the workspace
status_response=$(curl -s -X GET \
  -H "Authorization: Bearer $access_token" \
  https://api.fabric.microsoft.com/v1/workspaces/$WORKSPACE_ID/git/status)

# Extract parameters using Bash string manipulation
workspaceHead=$(echo "$status_response" | grep -o '"workspaceHead":"[^"]*' | sed 's/"workspaceHead":"//')
remoteCommitHash=$(echo "$status_response" | grep -o '"remoteCommitHash":"[^"]*' | sed 's/"remoteCommitHash":"//')

# Update the workspace from git
update_response=$(curl -X POST \
  -H "Authorization: Bearer $access_token" \
  -H "Content-Type: application/json" \
  -d '{
        "workspaceHead": "'"$workspaceHead"'",
        "remoteCommitHash": "'"$remoteCommitHash"'",
        "conflictResolution": {
          "conflictResolutionType": "Workspace",
          "conflictResolutionPolicy": "PreferWorkspace"
        },
        "options": {
          "allowOverrideItems": true
        }
      }' \
  https://api.fabric.microsoft.com/v1/workspaces/$WORKSPACE_ID/git/updateFromGit)

if [ "$update_response" = "null" ]; then
  exit 0;
else
  echo "$token_response"
  echo "$status_response"
  echo "$update_response";
  exit 1;
fi