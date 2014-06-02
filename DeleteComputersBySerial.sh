#!/bin/bash
#
########################################################################################################
#
# Copyright (c) 2014, JAMF Software, LLC.  All rights reserved.
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
#	This script deletes computer records from the JSS by their serial number based
#	on input from a delimited (by newline or comma) text file containing only serial numbers.
#
####################################################################################################
#
# HISTORY
#
#	Version 1.0
#  	Created by Nick Anderson, JAMF Software, LLC, on May 28, 2014
#
####################################################################################################

# User input
read -p "JSS URL (HTTPS Only): " server
read -p "JSS Username: " username
read -s -p "JSS Password: " password
echo ""
read -p "Data File Path (can be dragged into terminal): " input

# Reformat our input to csv
touch /tmp/serials.csv
cat $input | tr '\n' ',' > /tmp/serials.csv
file="/tmp/serials.csv"

# Count entries in file
count=`cat ${file} | awk -F, '{print NF}'`

# Start the count
index="0"

# Loop through the entries and send a deletion to the JSS for each of them
while [ $index -lt ${count} ]
do
	index=$[$index+1]
	var=`cat ${file} | awk -F, '{print $'"${index}"'}'`

	curl -v -k -u $username:$password $server/JSSResource/computers/serialnumber/$var -X DELETE
done

# Clean up
rm /tmp/serials.csv

exit 0
