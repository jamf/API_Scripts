#!/usr/bin/env python

# Limitations:
# - Only one device per student is supported
# - Classes may not contain a + or / character as the API cannot parse these at this time

# Settings
jssAddr = "https://localhost:8443" # JSS server address with or without https:// and port
jssUser = "api" # JSS login username (API privileges must be set)
jssPass = "api" # JSS login password
csvPath = "/tmp/studentCourse.csv" # Path and file name for the input CSV file
# Imports
from urllib2 import urlopen, URLError, HTTPError, Request
from xml.dom import minidom
from xml.sax import make_parser, ContentHandler
from sys import exc_info, argv, stdout, stdin
from getpass import getpass
import base64
import csv
import re

def main():
	global jssAddr
	global jssUser
	global jssPass
	global csvPath
	updateMDGroups = JSSUpdateMobileDeviceGroups()
	studentList = updateMDGroups.getCSVData(csvPath)
	updateMDGroups.updateGroups(jssAddr, jssUser, jssPass, studentList)	

		
class JSSUpdateMobileDeviceGroups:
	def __init__(self):
		self.numMobileDevicesUpdated = 0
		self.deviceMap = dict()
		self.unmanagedDeviceMap = dict()
		
	def getCSVData(self, csvPath):
		# Read in CSV
		csvinput = open(csvPath)
		reader = csv.reader(csvinput)
		return reader
	
	def updateGroups(self, jssAddr, jssUser, jssPass, studentList):
		# Cache mobile device ID to student username mapping
		self.grabMobileDeviceData(jssAddr, jssUser, jssPass)
		
		# Assign student device to the classes (groups)
		url = jssAddr + "/JSSResource/mobiledevicegroups"
		grabber = CasperGroupPUTHandler(jssUser, jssPass)
		for studentLine in studentList:
			if studentLine[0] != "Student ID":
				self.handleStudentDeviceAssignment(grabber, url, studentLine)
		print "Successfully updated %d devices in the JSS." % self.numMobileDevicesUpdated
		
	def grabMobileDeviceData(self, jssAddr, jssUser, jssPass):
		url = jssAddr + "/JSSResource/mobiledevices"
		grabber = CasperDeviceXMLGrabber(jssUser, jssPass)
		grabber.parseXML(url, CasperMobileDeviceListHandler(grabber, self.deviceMap, self.unmanagedDeviceMap))
		
	def handleStudentDeviceAssignment(self, grabber, url, studentLine):
		# Create mobile device studentLine XML...		
		if studentLine[0] in self.deviceMap:
			if "/" in studentLine[1] or "+" in studentLine[1]:
				print "Error: User: %s, Class: %s, Error: Class contains forward slash or ends in plus character" % (studentLine[0], studentLine[1])
			else:
				studentDeviceID = self.deviceMap[studentLine[0]]
				newGroupAssignment = self.createNewGroupElement(studentDeviceID, studentLine[1])
				self.handleGroupPUT(grabber, url, studentLine[1], newGroupAssignment)
		else:
			print "Error: User: %s, Class: %s, Error: Could not find a mobile device match for student username or device is unmanaged" % (studentLine[0], studentLine[1])
		
	def handleGroupPUT(self, grabber, url, className, newGroupAssignment):
		# PUT new XML
		apiClassURLRAW = url + "/name/" + className 
		apiClassURL = apiClassURLRAW.replace (' ', '+')
		apiClassName = className.replace ('+', '')
		apiClassName = apiClassName.replace (' ', '+')
		###########UNCOMMENT NEXT TWO LINES FOR DEBUG MODE#############
		#print "PUT-ing URL %s: " % (apiClassURL)
		#print newGroupAssignment.toprettyxml()
		putStatus = grabber.openXMLStream("%s/name/%s" % (url, apiClassName), newGroupAssignment)
		if putStatus is None:
			self.numMobileDevicesUpdated += 1
	
	def createNewGroupElement(self, studentDeviceID, groupName):
		global eventValues
		newGroupAssignment = minidom.Document()
		group = self.appendEmptyElement(newGroupAssignment, newGroupAssignment, "mobile_device_group")
		self.appendNewTextElement(newGroupAssignment, group, "name", groupName)
		groupAdditions = self.appendEmptyElement(newGroupAssignment, group, "mobile_device_additions")
		deviceElement = self.appendEmptyElement(newGroupAssignment, groupAdditions, "mobile_device")
		self.appendNewTextElement(newGroupAssignment, deviceElement, "id", studentDeviceID)
		return newGroupAssignment
	
	def appendEmptyElement(self, doc, section, newElementTag):
		newElement = doc.createElement(newElementTag)
		section.appendChild(newElement)
		return newElement
		
	def appendNewTextElement(self, doc, section, newElementTag, newElementValue):
		newElement = self.appendEmptyElement(doc, section, newElementTag)
		newValueElement = doc.createTextNode(newElementValue)
		newElement.appendChild(newValueElement)
		return newElement

class CasperDeviceXMLGrabber:
	def __init__(self, jssUser, jssPass):
		self.jssUser = jssUser
		self.jssPass = jssPass
		
	def parseXML(self, url, handler):
		req = Request(url)
		base64string = base64.encodestring('%s:%s' % (self.jssUser, self.jssPass))[:-1]
		authheader = "Basic %s" % base64string
		req.add_header("Authorization", authheader)
		try:
			MobileDeviceList = urlopen(req)
		except (URLError, HTTPError) as urlError: # Catch errors related to urlopen()
			print "Error when opening URL: " + urlError.__str__()
			exit(1)
		except: # Catch any unexpected problems and bail out of the program
			print "Unexpected error:", exc_info()[0]
			exit(1)
		parser = make_parser()
		parser.setContentHandler(handler)
		parser.parse(MobileDeviceList)
			
class CasperGroupPUTHandler:
	def __init__(self, jssUser, jssPass):
		self.jssUser = jssUser
		self.jssPass = jssPass
		
	def parseXML(self, url):
		return self.openXMLStream(url, None)
			
	def openXMLStream(self, url, xmlout):
		try:
			if xmlout is None:
				req = Request(url)
			else:
				req = Request(url, data=xmlout.toxml())
				req.add_header('Content-Type', 'text/xml')
				req.get_method = lambda: 'PUT'
			base64string = base64.encodestring('%s:%s' % (self.jssUser, self.jssPass))[:-1]
			authheader = "Basic %s" % base64string
			req.add_header("Authorization", authheader)
			xmldata = urlopen(req)
			if xmlout is None:
				xmldoc = minidom.parse(xmldata)
			else:
				xmldoc = None
			return xmldoc
		except (URLError, HTTPError) as urlError: # Catch errors related to urlopen()
			if urlError.code == 404:
				if xmlout is None:
					req = Request(url)
				else:
					req = Request(url, data=xmlout.toxml())
					req.add_header('Content-Type', 'text/xml')
					req.get_method = lambda: 'POST'
				base64string = base64.encodestring('%s:%s' % (self.jssUser, self.jssPass))[:-1]
				authheader = "Basic %s" % base64string
				req.add_header("Authorization", authheader)
				xmldata = urlopen(req)
				if xmlout is None:
					xmldoc = minidom.parse(xmldata)
				else:
					xmldoc = None
				return xmldoc
			print "Error when opening URL %s - %s " % (url, urlError.__str__())
			return "Error"
		except: # Catch any unexpected problems and bail out of the program
			print "Unexpected error:", exc_info()[0]
			exit(1)

# This class is used to parse the /mobiledevices list to get all of the ids and usernames
class CasperMobileDeviceListHandler(ContentHandler):
	def __init__(self, grabber, deviceMap, unmanagedDeviceMap):
		ContentHandler.__init__(self)
		self.grabber = grabber
		self.deviceMap = deviceMap
		self.unmanagedDeviceMap = unmanagedDeviceMap
		self.currentID = ""
		self.inID = False
		self.inSize = False
		self.inUsername = False
		self.inManaged = False
						
	def startElement(self, tag, attributes):
		if tag == "id":
			self.inID = True
		elif tag == "username":
			self.inUsername = True
		elif tag == "managed":
			self.inManaged = True	
		elif tag == "size":
			self.inSize = True
		
	def endElement(self, tag):
		self.inID = False
		self.inSize = False
		self.inManaged = False
		self.inUsername = False
		if tag == "mobiledevices":
			print "Finished collecting mobile devices for lookup"
		
	def characters(self, data):
		if self.inID:
			self.currentID = data

		elif self.inUsername:
			if data != "" and self.currentID not in self.unmanagedDeviceMap.values():
				self.deviceMap[data] = self.currentID

		elif self.inManaged:
			if data != "true":
				self.unmanagedDeviceMap[data] = self.currentID
								
		elif self.inSize:
			self.numDevices = data
			print "Collecting data for " + data + " Mobile Device(s)..."

if __name__ == "__main__":
	main()