#!/bin/sh

###########################################################################################################################
username="admin"
password="abc123"
jssapiurl="https://yourJSSUrl:8443"
###########################################################################################################################


# Download all invitiations from the JSS
echo "Downloading Data from JSS..."
curl -k -u $username:$password $jssapiurl/JSSResource/mobiledeviceinvitations -X GET | xmllint --format - >> /tmp/here.xml
echo "Received XML Data from JSS"

# Extract all Invitation ID's and save to a temp
echo "Parsing invitations..."
grep '<invitation' /tmp/here.xml | cut -f2 -d">"|cut -f1 -d"<" >> /tmp/ids.txt
invitations=(wc -l /tmp/ids.txt | awk '{print $2}')
echo "Found $invitations invitations!"

# For all found in tmp, curl a delete command for each
count=0
for line in $(cat /tmp/ids.txt); do
 echo "Deleting Invitation $line"
 curl -k -u $username:$password $jssapiurl/JSSResource/mobiledeviceinvitations/name/$line -X DELETE
 count=($count+1)
done
echo "Deleted $count invitations successfully!"

# Clean up temp files
rm -f /tmp/here.xml
rm -f /tmp/ids.txt
echo "Clean-up Completed"
