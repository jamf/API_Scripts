#!/bin/sh
########################################################################################################
#
# Copyright (c) 2013, JAMF Software, LLC.  All rights reserved.
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

# HARDCODED VARIABLES
apiusername="" # Username that has API privileges for 'Peripherals'
apipassword="" # Password for User that has API privileges for 'Peripherals'
jssbase="" # JSS base url e.g. "https://yourJSSurl:8443"

# CHECK FOR SCRIPT PARAMETERS IN JSS  
if [ "$4" != "" ] && [ "$apiusername" == "" ]
then
	apiusername="$4"
fi

if [ "$5" != "" ] && [ "$apipassword" == "" ]
then
	apipassword="$5"
fi

if [ "$6" != "" ] && [ "$jssbase" == "" ]
then
	jssbase="$6"
fi
####################################################################################################
# SCRIPT FUNCTIONS -  - DO NOT MODIFY BELOW THIS LINE
####################################################################################################

####################################################################################################
# FUNCTION - Get the serial number of a connected Thunderbolt Display
# $serial = serial number of Thunderbolt Display
####################################################################################################
function getSerialNumber() {
serial="$(/usr/sbin/system_profiler | egrep "Display Serial Number:" | awk '{print $4}')"
}

####################################################################################################
# FUNCTION - Get the Ethernet Interface MAC Addresses and save to variables en0 and en1 
# $en0 - MAC address of interface en0 e.g 01.02.03.04.05.06
# $en1 - MAC address of interface en1 e.g 01.02.03.04.05.06
####################################################################################################
function getInterface() {
# Get interfaces Ethernet Addresses 
for iface in  `ifconfig -lu` ; do
    case $iface in
    en0)
    	en0="$(/sbin/ifconfig en0 | grep ether | awk '{print $NF}' | tr ':' '.')" ;;
    en1)
    	en1="$(/sbin/ifconfig en1 | grep ether | awk '{print $NF}' | tr ':' '.')" ;;
    esac
done
}

####################################################################################################
# FUNCTION - Get the count of JSS Peripherals and next ID that we would use
# $sizeoutput - current count of JSS Peripherals
# $next - number of the next peripheral that we would need to use
####################################################################################################
function getNextPeripheral() {
# Find the Next Peripheral ID, if its needed later
sizeoutput="$(/usr/bin/curl -k -u $apiusername:$apipassword $jssbase/JSSResource/peripherals -X GET | sed -n -e 's/.*<size>\(.*\)<\/size>.*/\1/p')"
next=`expr $sizeoutput + 1`
}

####################################################################################################
# FUNCTION - Generate an xml file for use by the cURL POST
# $filename - Path to the temp file we are writing xml
####################################################################################################
function generatePostXMLFile() {
filename="/tmp/Peripheral.xml"
/usr/bin/touch $filename
echo "<?xml version="1.0" encoding="UTF-8" standalone="no"?>" >> $filename
echo "<peripheral>" >> $filename
echo "  <general>" >> $filename
echo "    <fields>" >> $filename
echo "      <type>Display</type>" >> $filename
echo "      <field>" >> $filename
echo "        <name>Manufacturer</name>" >> $filename
echo "        <value>Apple</value>" >> $filename
echo "      </field>" >> $filename
echo "      <field>" >> $filename
echo "        <name>Serial</name>" >> $filename
echo "        <value>$serial</value>" >> $filename
echo "      </field>" >> $filename
echo "    </fields>" >> $filename
echo "  </general>" >> $filename
echo "  <location>" >> $filename
echo "    <computer_id>$computerid</computer_id>" >> $filename
echo "  </location>" >> $filename
echo "</peripheral>" >> $filename
/usr/bin/xmllint -o $filename --format $filename
}

####################################################################################################
# FUNCTION - Generate an xml file for use by the cURL PUT
# $filename - Path to the temp file we are writing xml
####################################################################################################
function generatePutXMLFile() {
filename="/tmp/Peripheral.xml"
/usr/bin/touch /tmp/Peripheral.xml
echo "<?xml version="1.0" encoding="UTF-8" standalone="no"?>" >> $filename
echo "<peripheral>" >> $filename
echo "  <general>" >> $filename
echo "    <fields>" >> $filename
echo "      <field>" >> $filename
echo "        <name>Serial</name>" >> $filename
echo "        <value>$serial</value>" >> $filename
echo "      </field>" >> $filename
echo "    </fields>" >> $filename
echo "  </general>" >> $filename
echo "</peripheral>" >> $filename
/usr/bin/xmllint -o $filename --format $filename
}
####################################################################################################
# FUNCTION - Process to clean up after ourselves
####################################################################################################
function deleteXMLFile() {
/bin/rm $filename
}

####################################################################################################
# FUNCTION - Get information via the JSSAPI to get the computerid# and peripheral id number
# $computerapioutput - Full API output of current Computer Record in the JSS
# $computerid - The computer ID in the JSS
# $periid - Peripheral serial # in the JSS for this computer
####################################################################################################
function getJSSInformationen0() {
computerapioutput="$(/usr/bin/curl -k -u $apiusername:$apipassword $jssbase/JSSResource/computers/macaddress/$en0 -X GET)"
computerid="$(echo $computerapioutput | sed -n -e 's/.*<id>\(.*\)<\/id>.*/\1/p')"
periid="$(echo $computerapioutput | sed -n -e 's/.*<field_1>\(.*\)<\/field_1>.*/\1/p')"
}

####################################################################################################
# FUNCTION - Get information via the JSSAPI to get the computerid# and peripheral id number
# $computerapioutput - Full API output of current Computer Record in the JSS
# $computerid - The computer ID in the JSS
# $periid - Peripheral serial # in the JSS for this computer
####################################################################################################
function getJSSInformationen1() {
computerapioutput="$(/usr/bin/curl -k -u $apiusername:$apipassword $jssbase/JSSResource/computers/macaddress/$en1 -X GET)"
computerid="$(echo $computerapioutput | sed -n -e 's/.*<id>\(.*\)<\/id>.*/\1/p')"
periid="$(echo $computerapioutput | sed -n -e 's/.*<field_1>\(.*\)<\/field_1>.*/\1/p')"
}

####################################################################################################
# FUNCTION - cURL POST of the generatePostXMLFile function
####################################################################################################
function xmlPost() {
echo "No previous Thunderbolt display found in JSS, Creating record for $serial"
/usr/bin/curl -k -u $apiusername:$apipassword $jssbase/JSSResource/peripherals/id/$next -T "/tmp/Peripheral.xml" -X POST
}

####################################################################################################
# FUNCTION - cURL PUT of the generatePutXMLFile function
####################################################################################################
function xmlPut() {
echo "Different Thunderbolt display found in JSS, updating record to $serial"
/usr/bin/curl -k -u $apiusername:$apipassword $jssbase/JSSResource/peripherals/id/$periid -T "/tmp/Peripheral.xml" -X PUT
}

####################################################################################################
# FUNCTION - Notification that Serial# is already set correctly
####################################################################################################
function alreadySetMessage() {
echo "Thunderbolt display serial already set correctly"
echo "Display in JSS:   $perrid"
echo "Display attached: $serial"
}

####################################################################################################
# SCRIPT OPERATIONS -  - REALLY!!! - DO NOT MODIFY BELOW THIS LINE
####################################################################################################

getSerialNumber
if [ "$serial" != "" ]; then
	getInterface
	if [ "$en0" != "" ]; then
		getJSSInformationen0
		if [ "$periid" = "" ]; then
			getNextPeripheral
			generatePostXMLFile
			xmlPost
			deleteXMLFile
		elif [ "$periid" != "$serial" ]; then
			generatePutXMLFile
			xmlPut
			deleteXMLFile
			echo 
		else
			alreadySetMessage
		fi
	elif [ "$en1" != "" ]; then
		getJSSInformationen1
		if [ "$periid" = "" ]; then
			getNextPeripheral
			generatePostXMLFile
			xmlPost
			deleteXMLFile
		elif [ "$periid" != "$serial" ]; then
			generatePutXMLFile
			xmlPut
			deleteXMLFile
		else
			alreadySetMessage
		fi
	else
		echo "No Computer Record Found!"
	fi
else
	echo "No Thunderbolt Display Connected! - ABORT"
fi
