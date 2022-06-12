#!/bin/bash

# The MIT License (MIT)
# 
# Copyright (c) 2022 Carl Löndahl
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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

# https://stackoverflow.com/questions/296536/how-to-urlencode-data-for-curl-command
function rawurlencode {
    local string="${@}"
    local strlen=${#string}
    local encoded=""
    local pos c o

    for ((pos=0 ; pos<strlen ; pos++)); do
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

function sshf {
    MAC=$(grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' "$VM_PATH/config.plist")
    [ -z "$MAC" ] && error "$1 has no configured network."
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
    exit 0
}

# make sure #args are > 0
if [ $# -lt 1 ]; then
    help
fi

# handle arguments of length one
case "$1" in
    help ) help ;;
    list ) listvms && exit 0 ;;
    ip )   ips ;;
esac

# make sure VM exists
VM_NAME=${@:2}
VM_PATH="$UTM_ROOT/$VM_NAME.utm"
if [ ! -f "${VM_PATH}/config.plist" ]; then
    VM_NAME=$(ls $UTM_ROOT | grep -i "$VM_NAME" | sed -e 's/\.[a-z]*$//')
fi

if [ -z "$VM_NAME" ]; then
    error "${@:2} does not match a valid VM."
fi

RES="$(wc -l <<< "$VM_NAME")"
if [ "$RES" -gt 1 ]; then
    # if fzf is present, then we could invoke it here
    echo "$VM_NAME"
    exit 0
fi

# handle arguments of length two
VM_PATH="$UTM_ROOT/$VM_NAME.utm"
case "$1" in
    start )  cmd start "$VM_NAME" ;;
    pause )  cmd pause "$VM_NAME" ;;
    resume ) cmd resume "$VM_NAME" ;;
    stop )   cmd stop "$VM_NAME" ;;
    ssh )    sshf "$VM_NAME" ;;
    * )      help ;;
esac
