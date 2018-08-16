#!/home/pi/env/bin/python3

# mqtt_client.py
# Chris Jones 03/03/2018
# Mqtt client script

import sys
import os
import glob
import shutil
import signal
import time
import logging
import shlex
import argparse
import subprocess
import configparser
import timeout_decorator
import paho.mqtt.client as paho

# Config File
CONFIGFILE = os.path.expanduser(os.path.join('~', '.mqtt.conf'))

# Setup Logging
logging.basicConfig()
logger = logging.getLogger("daemon")
logger.setLevel(logging.DEBUG)

# Interrupt flag
interrupted = False

# mqtt response
mqttMsg = ""

# MQTT Info types
infoTypes = ("sensor", "state")
# MQTT Action types
actionTypes = ("outlet", "switch", "fan", "thermostat")

######## Functions #########

def cleanup():
    global interrupted
    interrupted = True
    print("Exception! Shutting down..")
    if activeProcess:
        activeProcess.kill() # send sigkill

def signal_handler(signal, frame):
    global interrupted
    interrupted = True
    print("Ctrl+C captured, stopping")
    sys.exit(0)
    
def get_arguments():
    parser = argparse.ArgumentParser(description="Send/receive mqtt data")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("-v", "--verbose", action="store_true")
    group.add_argument("-q", "--quiet", action="store_true")
    parser.add_argument("-i", "--input", nargs='*', action='store')
    parser.add_argument('-l', '--length', type=int, action='store')
    args = parser.parse_args()
    if len(sys.argv) > 1:
        # If input data is there but length override not set, calculate
        if (args.input and args.length == None):
           args.length = len(args.input)
        # If input missing and length missing, print help
        elif ( not args.input and args.length == None):
           print("No input provided!")
           parser.print_help()
           exit(1)
        return(args)
    else:
        print("No Argument provided!")
        parser.print_help()
        exit(1)

@timeout_decorator.timeout(10)        
def grab_status(topic, hostName, hostPort, authList):
    import paho.mqtt.subscribe as subscribe
    global mqttMsg
    # Subscribe to topic to grab current data from topic
    mqttMsg = subscribe.simple(topic, msg_count=1, hostname=hostName, port=hostPort, client_id="jarvis", keepalive=10, auth=authList)

def check_status(cmdStatus):
    # Compare command status to current status
    currentStatus = str(mqttMsg.payload, 'utf-8').upper()
    if currentStatus == cmdStatus:
        print("{0} {1} is already {2}".format(location, topic, state))
        return 0
    else:
        print("Turning", location, topic, state)
        return 1

@timeout_decorator.timeout(5)
def set_status(topic, state, hostName, hostPort, authList):
    import paho.mqtt.publish as publish
    global mqttMsg
    # Publish new state to topic
    publish.single(topic, state, hostname=hostName, port=hostPort, client_id="jarvis", keepalive=10, auth=authList)

###### Main ###########

# capture SIGINT signal, e.g., Ctrl+C
signal.signal(signal.SIGINT, signal_handler)

# Read config file
config = configparser.ConfigParser()
config.read(CONFIGFILE)

# Get mqtt settings
serverHost = config.get('settings', 'server')
serverPort = int(config.get('settings', 'port'))
serverUser = config.get('settings', 'user')
serverPass = config.get('settings', 'password')

# Grab list of sections/modes
topicList = config.sections()
# Remove first index (settings)
topicList.pop(0)

args = get_arguments()
if (args.input[0] != "" and args.length == 2):
    location = args.input[0]
    topic = args.input[1]
elif (args.input[0] != "" and args.length == 3):
    location = args.input[0]
    topic = args.input[1]
    state = args.input[2].upper()
elif (args.input[0] != "" and args.length == 4):
    location = args.input[0] + args.input[1]
    topic = args.input[2]
    state = args.input[3].upper()
else:
    print("Unknown arg data: ", inputString, args.length)
    exit(1)

# Get matching option data from args
mqttOption = str("{0} {1}".format(location, topic))
if mqttOption in topicList:
    mqttSubTopic = config.get(mqttOption, 'subtopic')
    mqttPubTopic = config.get(mqttOption, 'pubtopic')
    mqttType = config.get(mqttOption, 'type')
else:
    print("No matching mqtt options in config for: ", mqttOption)
    exit(1)

# Setup auth
mqttAuth = {'username':serverUser, 'password':serverPass}

# Handle topic based on type
# Information topic types
if mqttType in infoTypes:
    subscribeTopic = "{}#".format(mqttSubTopic)
    grab_status(subscribeTopic, serverHost, serverPort, mqttAuth)
    print(str(mqttMsg.payload, 'utf-8'))
# Actionable topic types
elif mqttType in actionTypes:
    subscribeTopic = "{}/#".format(mqttSubTopic)
    publishTopic = "{}".format(mqttPubTopic)
    grab_status(subscribeTopic, serverHost, serverPort, mqttAuth)
    if check_status(state):
        set_status(publishTopic, state, serverHost, serverPort, mqttAuth)
# Handle unknown type
else:
    print("Invalid mqtt type: ", mqttType)

exit(0)