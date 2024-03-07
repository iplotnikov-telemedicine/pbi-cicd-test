# Get access token
token_response=$(curl --location "https://login.windows.net/common/oauth2/token" \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --header "Cookie: fpc=AqaCGRSl6mZAgM-xxtlFBrbzHxbfAQAAADqaet0OAAAAYDQJkgEAAABEmnrdDgAAAA; stsservicecookie=estsfd; x-ms-gateway-slice=estsfd" \
    --data-urlencode "client_id=$CLIENT_ID" \
    --data-urlencode "grant_type=password" \
    --data-urlencode "resource=https://analysis.windows.net/powerbi/api" \
    --data-urlencode "username=igor.plotnikov@credentially.io" \
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


echo "$CLIENT_ID"
echo "$AZUSER_EMAIL"
echo "$TENANT_ID"
echo "<$workspaceHead>"
echo "<$remoteCommitHash>"
echo "<$access_token>"


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
  echo "Success"
else
  echo "$update_response"
fi