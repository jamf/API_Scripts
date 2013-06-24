#!/bin/sh
#Based on code by mm2270 https://jamfnation.jamfsoftware.com/discussion.html?id=7575
#Slightly modified else clause to re-check for en1 MAC by Bram Cohen


apiURL="https://your.casper.jss:8443/JSSResource/computers/macaddress/"
apiUser="apiusername"
apiPass="apipassword"
MacAdd=$( networksetup -getmacaddress en0 | awk '{ print $3 }' | sed 's/:/./g' )

ManAccount=$( curl -s -u $apiUser:$apiPass "$apiURL$MacAdd" | xpath /computer/general/remote_management/management_username[1] | sed 's/<management_username>//;s/<\/management_username>//' )
if [[ "$ManAccount" != "" ]]; then
  echo "<result>$ManAccount</result>"
else
	MacAdd=$( networksetup -getmacaddress en1 | awk '{ print $3 }' | sed 's/:/./g' )
	ManAccount=$( curl -s -u $apiUser:$apiPass "$apiURL$MacAdd" | xpath /computer/general/remote_management/management_username[1] | sed 's/<management_username>//;s/<\/management_username>//' )
	if [[ "$ManAccount" != "" ]]; then
		echo "<result>$ManAccount</result>"
	fi
fi
