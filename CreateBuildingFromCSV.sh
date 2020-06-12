#!/bin/bash

########################################################################################################
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
# DESCRIPTION
#
#	This script reads a CSV of buildings and imports them via the JSS API.  This script 
#	expects each building name to be on it's own line within the CSV file.
#
#
####################################################################################################

#Declare variables
server="yourJSS.jamfcloud.com"						        #Server name and port
username="admin"								#JSS username with API privileges
password="password"								#Password for the JSS account
file="/Users/admin/Desktop/Buildings.csv"					#Path to CSV

#Do not modify below this line

#Count the number of entries in the file so we know how many buildings to submit
count=`cat ${file} | awk -F, '{print NF}'`

#Set a variable to start counting how many buildings we've submitted
index="0"

#Loop through the building names and submit to the JSS until we've reached the end of the CSV
while IFS= read -r line || [ -n "$line" ]; do
	echo "<building><name>${line}</name></building>"
	curl -u ${username}:${password} -H "Content-Type: text/xml" https://${server}/JSSResource/buildings/id/0 -d "<building><name>${line}</name></building>" -X POST
done < $file

exit 0
