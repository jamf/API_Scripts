#!/bin/bash

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
#	This script will delete all user objects from the JSS without checking whether the
#	user is associated to a device or computer.  Requires JSS version 9.3+
#
#####################################################################################################
#
# HISTORY
#
#	Version 1.0
#  	Created by Sam Fortuna, JAMF Software, LLC, on July 15th, 2014
#
####################################################################################################

#Set variables here:
jssUser="admin"							#JSS username
jssPass="password"						#JSS password
jssURL="https://JSS.URL.com:8443/"		#Trailing slash required

###	DO NOT TOUCH BELOW THIS LINE

index="0"
users=()

#Get a list of Users
IDs=`curl -k -v -u $jssUser:$jssPass ${jssURL}JSSResource/users -X GET`
size=`echo $IDs | xpath //users/size | sed 's/<[^>]*>//g'`

#Show how many Users will be deleted
echo $size " user objects will be deleted."

#Put the IDs into an array
while [ $index -lt ${size} ] 
do	
	index=$[$index+1]
	users+=(`echo $IDs | xpath //users/user[${index}]/id | sed 's/<[^>]*>//g'`)
done

#Show the IDs of all Users that will be deleted
echo "The following user IDs will be deleted: " ${users[@]}

#Delete each User by ID
for i in "${users[@]}"
do
	curl -k -v -u $jssUser:$jssPass ${jssURL}JSSResource/users/id/${i} -X DELETE
done
