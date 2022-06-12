#!/bin/bash

usage="$(basename "$0") [argument] -- program to manage UTM

argument:
    help  show this help text
    list  list all virtual machines
    ip    list all IPs associated with QEMU
    
    {start, pause, resume, stop, ssh} [name]
    "

UTM_ROOT=$HOME/Library/Containers/com.utmapp.UTM/Data/Documents

function error {
    echo "Error: $@"
    exit 1
}

function rawurlencode {
    local string="${@}"
    local strlen=${#string}
    local encoded=""
    local pos c o

    for (( pos=0 ; pos<strlen ; pos++ )); do
        c=${string:$pos:1}
        case "$c" in
            [-_.~a-zA-Z0-9] ) o="${c}" ;;
            * )               printf -v o '%%%02x' "'$c"
        esac
        encoded+="${o}"
    done
    echo "${encoded}"
    REPLY="${encoded}"
}

function checkvm {
    VM_CONFIG_PATH="$UTM_ROOT/$1.utm/config.plist"
    if [ ! -f "${VM_CONFIG_PATH}" ]; then
        error "$1 is not a valid VM."
    fi
}

function sshf {
    VM_CONFIG_PATH="$UTM_ROOT/$1.utm/config.plist"
    MAC=$(grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' "$VM_CONFIG_PATH")
    IP=$(arp -an | grep -i "$MAC" | sed -n 's/.*\(192.168.6[0-9].[0-9]*\).*/\1/p')
    [ -z "$IP" ] && error "$1 is not running or connected to network."
    ssh $IP

}

function listvms {
    ls $UTM_ROOT | sed -e 's/\.[a-z]*$//'
}

function cmd {
    open -g "utm://$1?name=$( rawurlencode $2 )"
}

function sendtext {
    # not really needed, but left here
    open -g "utm://sendText?name=$( rawurlencode $1 )&text=$( rawurlencode ${@:2} )"
}

function ips {
    arp -an | sed -n 's/.*\(192.168.6[0-9].[0-9]*\).*/\1/p' | grep -v ".255"
}

function help {
    echo "$usage"
}

# make sure #args are > 0
if [ $# -lt 1 ]; then
    error "Not enough arguments."
fi

# make sure VM exists
if [ $# -gt 1 ]; then
    checkvm "${@:2}"
fi

case "$1" in
    help | -h | --help ) help ;;
    list | -l | --list ) listvms ;;
    start ) cmd start ${@:2} ;;
    pause ) cmd pause ${@:2} ;;
    resume ) cmd resume ${@:2} ;;
    stop ) cmd stop ${@:2} ;;
    ip ) ips ;;
    ssh ) sshf "${@:2}" ;;
    * ) help ;;
esac
