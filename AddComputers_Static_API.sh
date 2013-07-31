#!/bin/sh

#Enter in the name of the file path that we want to add to a static group
csvFilePath=""

#Uncomment your data stored in the CSV
#dataPref="Mac"
#dataPref="JSSID"
dataPref="Name"

#Enter in the ID of the static group we want to add the computer
groupID=""

#Enter in the URL of the JSS we are are pulling and pushing the data to. (NOTE: We will need the https:// and :8443. EX:https://jss.company.com:8443 )
jssURL=""

#Enter in a username and password that has the correct permissions to the JSS API for what data we need
jssUser=""
jssPass=""

#Default temp file name and path we will build for API submission
groupFilePath="/tmp/computerGroup.xml"


#####No configuration variables below this line.  You should not need to edit unless you are modifying functionality

#We will use these variable to build our xml file
a="<computer_group><computers>"
b="<computer>"
c="</computer>"
d="</computers></computer_group>"


#Build our array of values
echo "Building the array from CSV..."
v=`cat $csvFilePath`
PREV_IFS="$IFS" # Save previous IFS
IFS=, values=($v)
IFS="$PREV_IFS" # Restore IFS

#Build the XML from the array
echo "Building the xml at $groupFilePath..."
echo "$a" > "$groupFilePath"
for val in "${values[@]}"
  do
		echo "$b" >> "$groupFilePath"
		case  $dataPref  in
			"Mac")
				echo "<macaddress>$val</macaddress>" >> "$groupFilePath"
				;;
			"JSSID")
				echo "<id>$val</id>" >> "$groupFilePath"		
				;;
			"Name")
				echo "<name>$val</name>" >> "$groupFilePath"
				;;
			*)
				echo "error: no preference of CSV type was specified... Quitting..."
				exit 1
				;;
		esac
		echo "$c" >> "$groupFilePath"
done
	echo "$d" >> "$groupFilePath"
	
	#Submit group to JSS
	echo "File submitting to $jssURL..."
	curl -k -v -u $jssUser:$jssPass $jssURL/JSSResource/computergroups/id/$groupID -T "$groupFilePath" -X PUT

#Clean up
rm "$groupFilePath"



