#!/bin/bash

# Classic API > advancedusersearches > Updates an existing advanced user search by ID
#
# Created 10.13.2022 @robjschroeder

##################################################
# Variables -- edit as needed

# Jamf Pro API Credentials
jamfProAPIUsername=""
jamfProAPIPassword=""
jamfProURL=""

# ID value to filter by
id=""

# Sample Request Body, modify to fit your needs
requestBody="<advanced_user_search>
    <name>Advanced Search Name</name>
    <criteria>
        <criterion>
            <name>Email Address</name>
            <priority>0</priority>
            <and_or>and</and_or>
            <search_type>like</search_type>
            <value>company.com</value>
            <opening_paren>false</opening_paren>
            <closing_paren>false</closing_paren>
        </criterion>
    </criteria>
    <display_fields>
        <display_field>
            <name>Email Address</name>
        </display_field>
    </display_fields>
    <site>
        <id>-1</id>
        <name>None</name>
    </site>
</advanced_user_search>"

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

# Update existing advanced user search with request body
curl --request PUT \
--url ${jamfProURL}/JSSResource/advancedusersearches/id/${id} \
--header 'Accept: application/xml' \
--header 'Content-Type: application/xml' \
--header "Authorization: Bearer ${token}" \
--data "${requestBody}"


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
