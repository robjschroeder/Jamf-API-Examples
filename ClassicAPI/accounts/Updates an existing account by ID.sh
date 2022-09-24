#!/bin/bash

# Classic API > accounts > Updates an existing user by ID
#
# Created 09.23.2022 @robjschroeder

##################################################
# Variables -- edit as needed

# Jamf Pro API Credentials
jamfProAPIUsername=""
jamfProAPIPassword=""
jamfProURL=""

# ID value to filter by
userID=""

# Sample Request Body, modify to fit your needs
requestBody="<account>
    <name>John Smith</name>
    <directory_user>false</directory_user>
    <full_name>John Smith</full_name>
    <email>john.smith@company.com</email>
    <email_address>john.smith@company.com</email_address>
    <enabled>Enabled</enabled>
    <force_password_change>true</force_password_change>
    <access_level>Full Access</access_level>
    <privilege_set>Administrator</privilege_set>
    <password>sample</password>
    <site>
        <id>-1</id>
        <name>None</name>
    </site>
    <privileges>
        <jss_objects>
            <privilege>string</privilege>
        </jss_objects>
        <jss_settings>
            <privilege>string</privilege>
        </jss_settings>
        <jss_actions>
            <privilege>string</privilege>
        </jss_actions>
        <recon>
            <privilege>string</privilege>
        </recon>
        <casper_admin>
            <privilege>string</privilege>
        </casper_admin>
        <casper_remote>
            <privilege>string</privilege>
        </casper_remote>
        <casper_imaging>
            <privilege>string</privilege>
        </casper_imaging>
    </privileges>
</account>"

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

# Update existing user with request body
curl --request PUT \
--url ${jamfProURL}/JSSResource/accounts/userid/${userID} \
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
