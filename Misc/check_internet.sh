#!/bin/bash
# Simple script to test internet connectivity
PINGSITE="google.com"

echo "Confirming default gateway connectivity first."
defaultGateway=$( route | grep default | awk '{print $2}' )
if [ -n "$defaultGateway" ]; then
    echo "Default gateway is $defaultGateway."
    echo "Checking network connectivity to default Gateway now."
    if ping -c 1 "$defaultGateway" >> /dev/null 2>&1; then
        echo "Network connectivity to gateway appears to be working."
        echo "Moving on to internet ping test. Pinging $PINGSITE now."
        if ping -c 1 google.com >> /dev/null 2>&1; then
            echo "Ping test passed."
            echo "All tests passed. Internet appears to be working."
        else
            echo "Internet ping test failed. Checking DNS resolution."
            dnsResolve=$( host google.com | awk 'NR==1' )
            if [ -n "$dnsResolve" ]; then
                echo "$dnsResolve"
            else
                echo "Internet connectivity issues might be dns related."
            fi
            echo "Tests failed, internet is down."
            exit 1
        fi
    else
        echo "Network connectivity to default gateway appears to be down. Confirming local network connectivity."
        check_network.sh
        exit 1
    fi
else
    echo "No Default Gateway found. Confirming local network connectivity."
    check_network.sh
    exit 1
fi
exit 0
