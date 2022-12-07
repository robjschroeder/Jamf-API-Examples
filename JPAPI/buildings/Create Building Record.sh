#!/bin/bash

# Jamf Pro API > buildings > Create Building Record
#
# Created 12.07.2022 @robjschroeder

##################################################
# Variables -- edit as needed

# Jamf Pro API Credentials
jamfProAPIUsername=""
jamfProAPIPassword=""
jamfProURL=""

# Body Parameters
name=""
streetAddress1=""
streetAddress2=""
city=""
stateProvince=""
zipPostalCode=""
country=""

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

# Creates a new building
curl --request POST \
  --url ${jamfProURL}/api/v1/buildings \
  --header 'accept: application/json' \
  --header 'content-type: application/json' \
  --header "Authorization: Bearer ${token}" \
  --data '
{   
  "name": "'"${name}"'",
  "streetAddress1": "'"${streetAddress1}"'",
  "streetAddress2": "'"${streetAddress2}"'",
  "city": "'"${city}"'",
  "stateProvince": "'"${stateProvince}"'",
  "zipPostalCode": "'"${zipPostalCode}"'",
  "country": "'"${country}"'"
}
'


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
