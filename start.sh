#!/bin/sh

#
# - Run the unbound DNS resolver
#

HOST_IP=$(ip route | grep default | awk '{print $3}')
LOG="/var/log/unbound"

# Our colour profiles made easy
PURPLE='\033[35m'
GREEN='\033[92m'
RED='\033[31m'

# Trap and cleanup on ctrl-c
trap ctrl_c INT

function ctrl_c() {
    clear
    tput cvvis
    echo -n -e "** ${PURPLE}Unbound DNS resolver${GREEN} ➡ Exit\n\n"
    exit 0
}

# Add the root anchor
unbound-anchor -4 -a /var/lib/unbound/root.key

# Generate certificates for control
unbound-control-setup &>/dev/null

# Start service
tput civis; clear
echo -n -e "${PURPLE}Starting local resolver...${GREEN}"
unbound-control start

# Print occasional request count
RCOUNT=1
while true; do
    sleep 90
    NCOUNT=$(grep "info: $HOST_IP" $LOG | wc -l)
    if [[ "$NCOUNT" -gt "$RCOUNT" ]]; then
        echo -n -e "\n${PURPLE}[CHK]:${GREEN} Total requests ${PURPLE}[$NCOUNT]${GREEN}"
    fi
    RCOUNT=$NCOUNT
done &

# Format and log the output
echo -e "\nLogging requests..."
tail -f $LOG | while read -r LINE; do
    if [[ "$LINE" == *"info: $HOST_IP"* ]]; then
        DOMAIN=$(echo $LINE | cut -d: -f3 | cut -f 3 -d ' ' | tr -d '\n')
        REC=$(echo $LINE | cut -d: -f3 | cut -f 4- -d ' ' | tr -d '\n')

        # Longest record type to date is NSEC3PARAM
        # [XXX]: {DOMAIN} A {RECORD} = 21 chars
        if [[ ${#DOMAIN} -gt $(($(tput cols)-21)) ]]; then
            # $REC - 9 takes gives us a perfect fit
            FORMATTED=$(echo $DOMAIN | cut -b -$(($(tput cols)-${#REC}-9)))
            echo -n -e "\n${PURPLE}[REQ]:${GREEN} ${FORMATTED}* ${PURPLE}$REC${GREEN}"
        else
            echo -n -e "\n${PURPLE}[REQ]:${GREEN} ${DOMAIN} ${PURPLE}$REC${GREEN}"
        fi
    else
        OUT=$(echo $LINE | cut -d " " -f 3-)
        if [[ ${#OUT} -gt $(($(tput cols)-8)) ]]; then
            FORMATTED=$(echo $OUT | cut -b -$(($(tput cols)-8)))
            echo -n -e "\n${PURPLE}[SYS]:${GREEN} $FORMATTED*"
        else
            echo -n -e "\n${PURPLE}[SYS]:${GREEN} $OUT"
        fi
    fi
done
