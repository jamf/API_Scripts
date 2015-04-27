#!/usr/bin/python
# -*- coding: utf-8 -*-
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
# SUPPORT FOR THIS PROGRAM
#
#       This program is distributed "as is" by JAMF Software, LLC.
#
####################################################################################################
#
# ABOUT THIS PROGRAM
#
# NAME
#    updateDeviceInventoryBySmartGroup.py -- Update Mobile Device Inventory By Smart Group Membership
#
# SYNOPSIS
#    /usr/bin/python updateDeviceInventoryBySmartGroup.py
#    
# DESCRIPTION
#    This script was designed to update all mobile device inventory in a JSS Smart Group.
#
#    For the script to function properly, users must be running the JSS version 7.31 or later and
#    the account provided must have API privileges to "READ" and "UPDATE" mobile devices in the JSS.
#
####################################################################################################
#
# HISTORY
#
#    Version: 1.0
#
#    - Created by Nick Amundsen on June 23, 2011
#    - Updated by Bram Cohen on March 19, 2015
#       Added TLSv1 and new JSON Response on 9.6+
#
#    - Forked by Bram Cohen on April 27, 2015
#       - Chanaged to target groups instead of all devices
#
#####################################################################################################
#
# DEFINE VARIABLES & READ IN PARAMETERS
#
#####################################################################################################
#
# HARDCODED VALUES SET HERE
#
jss_host = "" #Example: "www.company.com" for a JSS at https://www.company.com:8443/jss
jss_port = "" #Example: "8443" for a JSS at https://www.company.com:8443/jss
jss_path = "" #Example: "jss" for a JSS at https://www.company.com:8443/jss
jss_username = "" #Example: Admin
jss_password = "" #Example: Password
jss_smart_group_id= "" #Example: "1"

##DONT EDIT BELOW THIS LINE
import sys 
import json
import httplib
import base64
import urllib2
import ssl
import socket

##Computer Object Definition
class Device:
    id = -1

##Check variable
def verifyVariable(name, value):
    if value == "":
        print "Error: Please specify a value for variable \"" + name + "\""
        sys.exit(1)

## the main function.
def main():
    verifyVariable("jss_host",jss_host)
    verifyVariable("jss_port",jss_port)
    verifyVariable("jss_username",jss_username)
    verifyVariable("jss_password",jss_password)
    devices=grabDeviceIDs()
    updateDeviceInventory(devices)

##Grab and parse the mobile devices and return them in an array.
def grabDeviceIDs():
    devices=[];
    ## parse the list
    for deviceListJSON in (getDeviceListFromJSS()["mobile_device_group"]["mobile_devices"]):
        d = Device()
        d.id = deviceListJSON.get("id")
        devices.append(d)  
    print "Found " + str(len(devices)) + " devices."
    return devices

##Create a header for the request
def getAuthHeader(u,p):
    # Compute base64 representation of the authentication token.
    token = base64.b64encode('%s:%s' % (u,p))
    return "Basic %s" % token

##Download a list of all mobile devices from the JSS API
def getDeviceListFromJSS():
    print "Getting device list from the JSS..."
    headers = {"Authorization":getAuthHeader(jss_username,jss_password),"Accept":"application/json"}
    try:
        conn = httplib.HTTPSConnection(jss_host,jss_port)
        sock = socket.create_connection((conn.host, conn.port), conn.timeout, conn.source_address)
        conn.sock = ssl.wrap_socket(sock, conn.key_file, conn.cert_file, ssl_version=ssl.PROTOCOL_TLSv1)
        conn.request("GET",jss_path + "/JSSResource/mobiledevicegroups/id/" + jss_smart_group_id,None,headers)
        data = conn.getresponse().read()
        conn.close()
        return json.loads(data)
    except httplib.HTTPException as inst:
        print "Exception: %s" % inst
        sys.exit(1)
    except ValueError as inst:
        print "Exception decoding JSON: %s" % inst
        sys.exit(1)

##Submit the command to update a device's inventory to the JSS
def updateDeviceInventory(devices):
    print "Updating Devices Inventory..."
    ##Parse through each device and submit the command to update inventory
    for index, device in enumerate(devices):
        percent = "%.2f" % (float(index) / float(len(devices)) * 100)
        print str(percent) + "% Complete -"
        submitDataToJSS(device)
    print "100.00% Complete"

##Update data for a single device
def submitDataToJSS(Device):
    print "\tSubmitting command to update device id " +  str(Device.id) + "..."
    try:
        url = "https://" + str(jss_host) + ":" + str(jss_port) + str(jss_path) + "/JSSResource/mobiledevices/id/" + str(Device.id)
        #Write out the XML string with new data to be submitted
        newDataString = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?><mobile_device><command>UpdateInventory</command></mobile_device>"
        #print "Data Sent: " + newDataString
        opener = urllib2.build_opener(urllib2.HTTPHandler)
        request = urllib2.Request(url,newDataString)
        request.add_header("Authorization", getAuthHeader(jss_username,jss_password))
        request.add_header('Content-Type', 'application/xml')
        request.get_method = lambda: 'PUT'
        opener.open(request)
    except httplib.HTTPException as inst:
        print "\tException: %s" % inst
    except ValueError as inst:
        print "\tException submitting PUT XML: %s" % inst
    except urllib2.HTTPError as inst:
        print "\tException submitting PUT XML: %s" % inst
    except:
        print "\tUnknown error submitting PUT XML."

## Code starts executing here. Just call main.
main()
