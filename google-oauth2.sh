#!/bin/bash

# A simple cURL OAuth2 authenticator
#
# Usage:
#	./google-oauth2.sh create - authenticates a user
#	./google-oauth2.sh refresh <token> - gets a new token
#
# Set CLIENT_ID and CLIENT_SECRET and SCOPE

#!/bin/bashset -e

CLIENT_ID=""
CLIENT_SECRET=""
SCOPE=${SCOPE:-"https://www.googleapis.com/auth/drive.file"}
#SCOPE=${SCOPE:-"https://docs.google.com/feeds"}

if [ -e $HOME/.googledrive.conf ]
then
    . $HOME/.googledrive.conf
fi

if [ -z "$CLIENT_ID" ]
then
    read -p "Client ID: " CLIENT_ID
    unset token
    echo "CLIENT_ID=$CLIENT_ID" >> $HOME/.googledrive.conf
fi

if [ -z "$CLIENT_SECRET" ]
then
    read -p "Client Secret: " CLIENT_SECRET
    unset token
    echo "CLIENT_SECRET=$CLIENT_SECRET" >> $HOME/.googledrive.conf
fi

# Method to extract data from json response
function jsonValue() {
KEY=$1
num=$2
awk -F"[:,}][^://]" '{for(i=1;i<=NF;i++){if($i~/\042'$KEY'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${num}p | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/[,]*$//'
}

if [ "$1" == "create" ]; then
	RESPONSE=`curl --silent "https://accounts.google.com/o/oauth2/device/code" --data "client_id=$CLIENT_ID&scope=$SCOPE"`
	DEVICE_CODE=`echo "$RESPONSE" | jsonValue device_code`
	USER_CODE=`echo "$RESPONSE" | jsonValue user_code`
	URL=`echo "$RESPONSE" | jsonValue verification_url`

	echo -n "Go to $URL and enter $USER_CODE to grant access to this application. Hit enter when done..."
	read

	RESPONSE=`curl --silent "https://accounts.google.com/o/oauth2/token" --data "client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&code=$DEVICE_CODE&grant_type=http://oauth.net/grant_type/device/1.0"`

	ACCESS_TOKEN=`echo "$RESPONSE" | jsonValue access_token`
	REFRESH_TOKEN=`echo "$RESPONSE" | jsonValue refresh_token`

	echo "Access Token: $ACCESS_TOKEN"
	echo "Refresh Token: $REFRESH_TOKEN"
elif [ "$1" == "refresh" ]; then
	REFRESH_TOKEN=$2
	RESPONSE=`curl --silent "https://accounts.google.com/o/oauth2/token" --data "client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&refresh_token=$REFRESH_TOKEN&grant_type=refresh_token"`

	ACCESS_TOKEN=`echo $RESPONSE | jsonValue access_token`
	
	echo "Access Token: $ACCESS_TOKEN"
fi
