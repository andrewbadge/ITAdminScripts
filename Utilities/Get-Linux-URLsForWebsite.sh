#!/bin/sh
#SYNOPSIS
#   Gets all the URLs a website references
#DESCRIPTION
#   Gets all the URLs a website references; images, AD tracking URLs, APIs
#   Useful to determine address to unblock in Umbrella or if a website has been compromised (Coinminer injected etc).
#NOTES
#    File Name      : Get-Linux-URLsForWebsite.sh
#    Author         : Andrew Badge
#    Prerequisite   : pcregrep: use "sudo apt install pcregrep" to install
#EXAMPLE 
#   Get-URLs "https://www.exigence.com.au"
#

Get-URLs()
{
    WEBADDRESS=$1
    curl -s $WEBADDRESS | pcregrep -o "(http:\/\/|https:\/\/).*?(?=\"|'| )" | sort -u
}
