#!/bin/bash
# Simple script to test local network connectivity
echo "Running preliminary tests."
ipAddr=$( ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' )
if [ -n "$ipAddr" ]; then
    echo "Connected to the network."
    echo "Ip address is $ipAddr."
    echo "Checking network routing now."
    defaultGateway=$( route | grep default | awk '{print $2}' )
    if [ -n "$defaultGateway" ]; then
        echo "Default gateway is $defaultGateway."
        echo "Checking network connectivity to default Gateway now."
        if ping -c 1 "$defaultGateway" >> /dev/null 2>&1; then
            echo "Network connectivity to gateway appears to be working."
            echo "All tests completed, and passed."
            echo "Local network connectivity is working."
        else
            echo "Network connectivity gateway appears to be down."
            exit 1
        fi
    else
        echo "No Default Gateway found. Local connectivity has failed"
        exit 1
    fi
else
    echo "No ip address found, currently not connected to a network."
    exit 1
fi
exit 0
