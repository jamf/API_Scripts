#!/bin/bash

####################################################################################################
#
# Copyright (c) 2015, JAMF Software, LLC.  All rights reserved.
#
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are met:
#               * Redistributions of source code must retain the above copyright
#                 notice, this list of conditions and the following disclaimer.
#               * Redistributions in binary form must reproduce the above copyright
#                 notice, this list of conditions and the following disclaimer in the
#                 documentation and/or other materials provided with the distribution.
#               * Neither the name of the JAMF Software, LLC nor the
#                 names of its contributors may be used to endorse or promote products
#                 derived from this software without specific prior written permission.
#
#       THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
#       EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#      
####################################################################################################
#      
#      General Changelog
#      
#      v0.0 - General API template created
#      				Nick Anderson
#      v0.1 - Re-aimed all API queries at mobile device applications and stored values
#             from returned information
#      				Katie Davis
#      v0.2 - Informative output and appIconID logic added
#      				Matthew Boyle
#      v1.0 - Fixed appIconID logic, added queries to iTunes API to parse for icon ID, download and
#             convert icon to base64 and upload icon to the JSS, fixed streamlined credential mode
#      				Nick Anderson
#         
####################################################################################################
#      
#      Purpose and Use
#      
#      The purpose of this script is to find any mobile device applications in the JSS that do not
#      have an icon associated with them, and upload an icon for that application. As with any
#      script that makes bulk changes to the JSS, it is advised to make a database backup.
#      
####################################################################################################

if [ -z "$1" ] ; then
	# Prompt the user for information to connect to the JSS with
	read -p "JSS URL: " jssurl
	read -p "JSS Username: " jssuser
	read -s -p "JSS Password: " jsspassword
	echo ""
else
	# Quick testing credentials, run the script with any trailing flag to use this mode
	jssurl="https://jss.com:8443"
	jssuser="admin"
	jsspassword="password"
fi


# Set a counter for our 'for' to start at the beginning
index="0"
# Create an array for apps
apps=()

# Get all of the app records
IDs=`curl -k -u $jssuser:$jsspassword ${jssurl}/JSSResource/mobiledeviceapplications -X GET`
# Record the number of apps to be put into the array from the returned XML
size=`echo $IDs | xpath //mobile_device_applications/size | sed 's/<[^>]*>//g'`

# Sort the app IDs into an array (using the start point of index=0 and the size variable as the end point)
while [ $index -lt ${size} ]
do
index=$[index+1]
apps+=(`echo $IDs | xpath //mobile_device_applications/mobile_device_application[${index}]/id | sed 's/<[^>]*>//g'`)
done

for i in "${apps[@]}"
do
# Tell the terminal which inventory record we're working on
echo "$(tput setaf 2)Scanning ${i}$(tput sgr0)"
# Collect the comprehensive inventory information for what we're checking in the array
app=`curl -s -k -u $jssuser:$jsspassword ${jssurl}/JSSResource/mobiledeviceapplications/id/${i} -X GET`

# Filter the information down to prevent contamination to our greps
#appInfo=`echo $app | xpath //mobile_device_application | sed 's/<[^>]*>//g'`
appName=`echo $app | xpath //mobile_device_application/general/name | sed 's/<[^>]*>//g'`
appVersion=`echo $app | xpath //mobile_device_application/general/version | sed 's/<[^>]*>//g'`
appExternalUrl=`echo $app | xpath //mobile_device_application/general/external_url | sed 's/<[^>]*>//g'`
appIconID=`echo $app | xpath //mobile_device_application/general/icon/id | sed 's/<[^>]*>//g'`
appAdamID=`echo $appExternalUrl | perl -lne 'print $1 if /(^.*)(?=\?)/'`
appAdamID2=`echo $appAdamID | sed 's/[^0-9]*//g'`

# If the application ID is not found or is lower than zero,
if [[ ! -z $appIconID ]]; then 
    echo "$(tput setaf 2)${appName} is good...$(tput sgr0)"
 else
     echo "${appName} | ${appAdamID2} | ${appIconID}" 

	# Grab the JSON data from iTunes and filter it down to the icon URL
	iconUrl=`curl http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/wa/wsLookup?id=$appAdamID2 | python -mjson.tool | grep artworkUrl512 | grep -o '['"'"'"][^"'"'"']*['"'"'"]' | tr -d '"'`

	# Curl the icon's URL and convert it to base64 for upload into the JSS
	iconData=`curl $iconUrl | openssl base64`

	# Submit our new icon to the JSS # ${iconUrl:(-12)}
	curl -s -k -u $jssuser:$jsspassword -H "Content-Type: text/xml" ${jssurl}/JSSResource/mobiledeviceapplications/id/${i} -d "<mobile_device_application><general><icon><name>${iconUrl:(-12)}</name><data>$iconData</data></icon></general></mobile_device_application>" -X PUT

 fi
done
