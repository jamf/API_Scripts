#!/bin/bash
# Script to delete users that are not associated with computers, devices, or VPP assignments

read -p "JSS URL: " jssURL
read -p "JSS Username: " jssUser
read -s -p "JSS Password: " jssPass
echo "" # secret flag fails to newline

index="0"
users=()

#Get a list of Users
IDs=`curl -k -u $jssUser:$jssPass ${jssURL}/JSSResource/users -X GET`
size=`echo $IDs | xpath //users/size | sed 's/<[^>]*>//g'`
echo "IDs: $IDs"

echo $size " user objects will be scanned."

#Put the IDs into an array
while [ $index -lt ${size} ] 
do	
	index=$[$index+1]
	users+=(`echo $IDs | xpath //users/user[${index}]/id | sed 's/<[^>]*>//g'`)
done


# Sort through each user ID individually and grep for IDs in computer, device, and vpp links
for i in "${users[@]}"
do
	echo "Checking on ${i}"
	user=`curl -k -u $jssUser:$jssPass ${jssURL}/JSSResource/users/id/${i} -X GET`
	computers=`echo $user | xpath //user/links/computers | grep id`
	devices=`echo $user | xpath //user/links/mobile_devices | grep id`
	vpp=`echo $user | xpath //user/links/vpp_assignments | grep id`
	# Delete users that meet our criteria
	if [[ -z "$computers" && -z "$devices" && -z "$vpp" ]] ; then
		echo "Deleting ${i}"
		curl -k -v -u $jssUser:$jssPass ${jssURL}/JSSResource/users/id/${i} -X DELETE
	fi
done
