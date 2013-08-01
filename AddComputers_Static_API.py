#!/usr/bin/python

import StringIO
import csv
from urllib2 import urlopen, URLError, HTTPError, Request
import base64

#path to CSV file
csvfile='/Users/Shared/computers.csv'
#Use full REST url for JSS URL
#Example: jssurl='https://jss.company.com:8443/JSSResource/computergroups/id/7'
jssurl=''

jssuser=''
jsspass=''

#open the csv
with open (csvfile, 'r') as myfile:
    data=myfile.read().replace('\n', '')

#create a list from the csv
f = StringIO.StringIO(data)
reader = csv.reader(f, delimiter=',')

#format the data from list into a xml
csvdata = '<computer_group><computers>\n'
for row in reader:
  for w in row:
		csvdata += '<computer><name>' + w + '</name></computer>\n'

csvdata += '</computers></computer_group>'

#print out contents as an error check
print('contents of data:\n' + csvdata)
					
#submit to the JSS API
req = Request(jssurl, data=csvdata)
req.add_header('Content-Type', 'text/xml')
req.get_method = lambda: 'PUT'
base64string = base64.encodestring(jssuser+':'+jsspass)[:-1]
authheader = "Basic %s" % base64string
req.add_header("Authorization", authheader)
xmldata = urlopen(req)

#print result
print(xmldata)
