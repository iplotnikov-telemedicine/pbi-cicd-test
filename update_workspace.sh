#!/bin/bash

AZUSERPASSWORD=$AZUSERPASSWORD
AZUSER_EMAIL=$AZUSER_EMAIL
CLIENT_ID=$CLIENT_ID
TENANT_ID=$TENANT_ID
WORKSPACE_ID=$WORKSPACE_ID


echo "AZUSERPASSWORD is $AZUSERPASSWORD"
echo "AZUSER_EMAIL is $AZUSER_EMAIL"
echo "CLIENT_ID is $CLIENT_ID"
echo "TENANT_ID is $TENANT_ID"
echo "WORKSPACE_ID is $WORKSPACE_ID"

# Get access token
token_response=$(curl --location "https://login.windows.net/common/oauth2/token" \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --header "Cookie: fpc=AqaCGRSl6mZAgM-xxtlFBrbzHxbfAQAAADqaet0OAAAAYDQJkgEAAABEmnrdDgAAAA; stsservicecookie=estsfd; x-ms-gateway-slice=estsfd" \
    --data-urlencode "client_id=$CLIENT_ID" \
    --data-urlencode "grant_type=password" \
    --data-urlencode "resource=https://analysis.windows.net/powerbi/api" \
    --data-urlencode "username=$AZUSER_EMAIL" \
    --data-urlencode "password=$AZUSERPASSWORD" \
    --data-urlencode "tenant_id=$TENANT_ID")

access_token=$(echo "$token_response" | grep -o '"access_token":"[^"]*' | awk -F'"' '{print $4}')

# Get status of the workspace
status_response=$(curl -s -X GET \
  -H "Authorization: Bearer $access_token" \
  https://api.fabric.microsoft.com/v1/workspaces/$WORKSPACE_ID/git/status)

# Extract parameters using Bash string manipulation
workspaceHead=$(echo "$status_response" | grep -o '"workspaceHead":"[^"]*' | sed 's/"workspaceHead":"//')
remoteCommitHash=$(echo "$status_response" | grep -o '"remoteCommitHash":"[^"]*' | sed 's/"remoteCommitHash":"//')


echo "<workspaceHead is $workspaceHead>"
echo "<remoteCommitHash is $remoteCommitHash>"
echo "<access_token is $access_token>"


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
  exit 1;
fi