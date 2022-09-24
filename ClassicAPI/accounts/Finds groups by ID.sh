#!/bin/bash

# Classic API > accounts > Finds groups by ID
#
# Created 09.23.2022 @robjschroeder

##################################################
# Variables -- edit as needed

# Jamf Pro API Credentials
jamfProAPIUsername=""
jamfProAPIPassword=""
jamfProURL=""

# ID value to filter by
groupID=""

# Token declarations
token=""
tokenExpirationEpoch="0"

#
##################################################

# Encode credentials
encodedCredentials=$( printf "${jamfProAPIUsername}:${jamfProAPIPassword}" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )
authToken=$(/usr/bin/curl -s -H "Authorization: Basic ${encodedCredentials}" "${jamfProURL}"/api/v1/auth/token -X POST)
token=$(/bin/echo "${authToken}" | /usr/bin/plutil -extract token raw -)
tokenExpiration=$(/bin/echo "${authToken}" | /usr/bin/plutil -extract expires raw - | /usr/bin/awk -F . '{print $1}')
tokenExpirationEpoch=$(/bin/date -j -f "%Y-%m-%dT%T" "${tokenExpiration}" +"%s")
/bin/echo "Token will expire: ${tokenExpiration}"

# Finds all accounts
curl --request GET \
--url ${jamfProURL}/JSSResource/accounts/groupid/${groupID} \
--header 'accept: application/xml' \
--header "Authorization: Bearer ${token}"


# Invalidate token
responseCode=$(/usr/bin/curl -w "%{http_code}" -H "Authorization: Bearer ${token}" ${jamfProURL}/api/v1/auth/invalidate-token -X POST -s -o /dev/null)
if [[ ${responseCode} == 204 ]]; then
	/bin/echo "" && /bin/echo "Token successfully invalidated"
	token=""
	tokenExpirationEpoch="0"
elif [[ ${responseCode} == 401 ]]; then
	/bin/echo "" && /bin/echo "Token already invalid"
else
	/bin/echo "" && /bin/echo "An unknown error occurred invalidating the token"
fi

exit 0
