#!/usr/bin/env bash
####################################################################################################
#Script Name	: get_my_public_ip.sh                                                                                             
#Description	: Script that gets my public IP.
#                 The script makes a request to a website and scrapes my IP address from the body of
#                 the response (HTML).
#                                                                                 
#Args           :                                                                                           
#Author       	: Francisco Güemes                                                
#Email         	: francisco@franciscoguemes.com                                           
#See also	    : https://askubuntu.com/questions/95910/command-for-determining-my-public-ip
#                   
####################################################################################################

#set -eux

#-----------------------------------------------------------------------------
# Site variable definition.
#-----------------------------------------------------------------------------
readonly SITE=http://ip4.me/

curl -s $SITE | grep -Eo "([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}"

# The exact same functionality as before but with a PCRE regex. Note the -P argument in grep.
#curl -s $SITE | grep -Po "(\d{1,3}\.){3}\d{1,3}"

# The exact same functionality but using a third party API:
#curl https://ipinfo.io/ip

