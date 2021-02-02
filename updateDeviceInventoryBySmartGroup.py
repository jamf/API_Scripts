#!/usr/bin/python
​
# Script to send remote MDM commands to managed devices via Jamf Pro API
# Please see end of script for license information
​
import requests
import time
​
jss_url = "https://your.jamfcloud.com"  # include :<port> if other than 443, omit trailing /
api_user = "api"
api_pass = "apiusrpass"
​
# This next setting requires some thought. Jamf's API swagger docs suggest sending
# remote commands to one device at a time, not to a big list. That's because if
# you send a command to a list and one of the device IDs doesn't exist, the whole
# command fails. Also, if you set this too high, you can create a thundering herd
# of device checkins. Also, you have to think about network. Like if you tell 10K
# devices to update iOS at the same time, your network admin will not be happy
# with you. On the other hand, if you have to do something to thousands of devices,
# one at a time may be way too slow.
number_of_devices_per_batch = 10
​
seconds_between_batches = 1  # Delay between batches
kind_of_group = "computer"  # "computer" or "mobiledevice"
group_name = "All Managed Mac"
remote_mdm_command_to_send = "BlankPush"
​
# Remote Commands for Mobile Devices groups:
# Commands supported: Settings, EraseDevice, ClearPasscode, UnmanageDevice,
# UpdateInventory, ClearRestrictionsPassword, SettingsEnableDataRoaming,
# SettingsDisableDataRoaming, SettingsEnableVoiceRoaming,
# SettingsDisableVoiceRoaming, SettingsEnableAppAnalytics,
# SettingsDisableAppAnalytics, SettingsEnableDiagnosticSubmission,
# SettingsDisableDiagnosticSubmission, SettingsEnableBluetooth,
# SettingsDisableBluetooth (iOS 11.3+ and supervised only),
# SettingsEnablePersonalHotspot, SettingsDisablePersonalHotspot, BlankPush,
# ShutDownDevice (supervised only), RestartDevice (supervised only),
# PasscodeLockGracePeriod (shared iPad only), EnableLostMode (supervised only),
# DisableLostMode (supervised and in lost mode only), DeviceLocation (supervised
# and in lost mode only), PlayLostModeSound (supervised and in lost mode only)
​
# Remote Commands for Computer groups:
# Commands supported: UnmanageDevice, BlankPush, SettingsEnableBluetooth,
# SettingsDisableBluetooth (macOS 10.13.4 and later), EnableRemoteDesktop (macOS 10.14.4 and later),
# DisableRemoteDesktop (macOS 10.14.4 and later), ScheduleOSUpdate.
​
​
def send_api_request(my_url, my_api_user, my_api_pass, my_method="GET", response_format='json', xml=''):
    print(f"[debug][send_api_request][start] {my_method} : {my_url}")
    response_format_header = {'Accept': 'text/xml'} if response_format == "xml" else {'Accept': 'application/json'}
    try:
        if my_method == "POST":
            r = requests.post(my_url, headers=response_format_header, auth=(api_user, api_pass), data=xml)
        elif my_method == "PUT":
            r = requests.put(my_url, headers=response_format_header, auth=(api_user, api_pass), data=xml)
        elif my_method == "DELETE":
            r = requests.delete(my_url, headers=response_format_header, auth=(api_user, api_pass))
        elif my_method == "GET":
            r = requests.get(my_url, headers=response_format_header, auth=(api_user, api_pass))
        else:
            raise SystemExit("An unhandled HTTP Method was requested.")
        r.raise_for_status()
        return r
    except requests.exceptions.HTTPError as e:
        # print("Http Error:", e)
        # print(f"Request failed with error code - {r.status_code}")
        if r.status_code == 401:
            print('HTTP Error 401 : Authentication failed. Check your JSS credentials and permissions.')
        elif r.status_code == 404:
            print('HTTP Error 404 : The JSS could not find the resource you were requesting. Check the URL.')
        else:
            print(r.status_code)
            print(r.text)
            print(r.reason)
        return
    except requests.exceptions.Timeout:
        print("HTTP Timeout")
        # Maybe set up for a retry, or continue in a retry loop
    except requests.exceptions.TooManyRedirects:
        print("HTTP Error - Too many redirects")
        # Tell the user their URL was bad and try a different one
    except requests.exceptions.RequestException as e:
        print("HTTP error")
        # catastrophic error. bail.
        raise SystemExit(e)
​
​
def get_group_id_from_name(my_jss_url, my_api_user, my_api_pass, my_kind_of_group, my_group_name):
    print(f"[debug][get_group_id_from_name][start] Getting ID for {my_kind_of_group} group {my_group_name}")
    group_name_urlencoded = requests.utils.quote(my_group_name)
    if my_kind_of_group == "computer":
        api_endpoint = f"{my_jss_url}/JSSResource/computergroups/name/{group_name_urlencoded}"
    elif my_kind_of_group == "mobiledevice":
        api_endpoint = f"{my_jss_url}/JSSResource/computergroups/name/{group_name_urlencoded}"
    else:
        raise SystemExit("Invalid my_kind_of_group parameter.")
    api_response = send_api_request(api_endpoint, my_api_user, my_api_pass)
    if api_response:
        group_id = api_response.json()['computer_group']['id']
        print(f"[debug][get_group_id_from_name] The group id is {group_id}")
        return group_id
    else:
        raise SystemExit("[error][exit] Could not locate the requested group. I'm giving up.")
​
​
def get_group_members(my_jss_url, my_api_user, my_api_pass, my_kind_of_group, my_group_name):
    print(f"[debug][getComputerGroupMembers][start] Getting members of {my_kind_of_group} group \"{my_group_name}\"")
    group_id_str = get_group_id_from_name(my_jss_url, my_api_user, my_api_pass, my_kind_of_group, my_group_name)
    if my_kind_of_group == "computer":
        api_endpoint = f"{my_jss_url}/JSSResource/computergroups/id/{group_id_str}"
    elif my_kind_of_group == "mobiledevice":
        api_endpoint = f"{my_jss_url}/JSSResource/computergroups/id/{group_id_str}"
    else:
        raise SystemExit("Invalid group type parameter. Should be \"computer\" or \"mobiledevice\"")
    api_response = send_api_request(api_endpoint, my_api_user, my_api_pass)
    if api_response:
        if my_kind_of_group == "computer":
            members_json = api_response.json()['computer_group']['computers']
        elif my_kind_of_group == "mobiledevice":
            members_json = api_response.json()['mobile_device_group']['mobile_devices']
        else:
            raise SystemExit("Invalid group type parameter. Should be \"computer\" or \"mobiledevice\"")
        my_computer_group_member_ids = []
        for member in members_json:
            if "id" in member:
                my_computer_group_member_ids.append(str(member["id"]))
        return my_computer_group_member_ids
​
​
def send_mdm_command(my_jss_url, my_api_user, my_api_pass, my_kind_of_group, my_remote_mdm_command_to_send, my_device_id_batch):
    print(
        f"[send_mdm_command][start] Sending {my_remote_mdm_command_to_send} command to {my_kind_of_group} ids {my_device_id_batch}")
    id_range_as_str = ','.join(my_device_id_batch)
    url = f"{my_jss_url}/JSSResource/{my_kind_of_group}commands/command/{my_remote_mdm_command_to_send}/id/{id_range_as_str}"
    push_response = send_api_request(url, my_api_user, my_api_pass, "POST")
    reason = "Command request sent to Jamf Pro" if push_response.status_code == 201 else push_response.reason
    print(f"[main][result] {push_response.status_code} : {reason}")
​
​
if __name__ == '__main__':
    group_member_ids = get_group_members(jss_url, api_user, api_pass, kind_of_group, group_name)
    # print(group_member_ids)
    for i in range(0, len(group_member_ids), number_of_devices_per_batch):
        device_id_batch = group_member_ids[i:i + number_of_devices_per_batch]
        send_mdm_command(jss_url, api_user, api_pass, kind_of_group, remote_mdm_command_to_send, device_id_batch)
        time.sleep(seconds_between_batches)
​
​
####################################################################################################
#
# Copyright (c) 2021, JAMF Software, LLC.  All rights reserved.
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
#       This program is distributed "as is".
#
####################################################################################################
#
# ABOUT THIS PROGRAM
#
# NAME
#    JamfProAPIMassActionOnGroup.py.py -- Send mdm commands to a group of devices
#
# SYNOPSIS
#    /usr/bin/python JamfProAPIMassActionOnGroup.py
#    
# REQUIREMENTS
#    A version of Jamf Pro exposing the Classic API.  
#    A Static or Smart group containing the target devices.
#    An API user that has permission to read group membership and send remote commands.
#    Set the API User/Password, Group Name, and desired command variables at the top of the script.
#
####################################################################################################
#
# HISTORY
#
#    Version: 1.0/ol
#
#    - Adapted previous version by Nick and Bram to...
#       - Use py3 with requests
#       - Command configurable with user var
#       - Support for computers or mobile devices
#
