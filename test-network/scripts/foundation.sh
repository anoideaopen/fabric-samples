#!/bin/bash

function robotSki(){
    key_user2="$(priv_user_by_org "org1" "User2")"
    ski="$(tool_ski "$key_user2")"
    echo $ski
}

function backendSki(){
    key_user1="$(priv_user_by_org "org1" "User1")"
    ski="$(tool_ski "$key_user1")"
    echo $ski
}

function adminValidator(){
    admin="$(foundation_admin_base58)"
    echo $admin
}

function adminAdress(){
    adminch="$(foundation_admin_base58check)"
    echo $adminch
}

function priv_user_by_org() {
    ORG=$1
    USER=$2
    echo "organizations/peerOrganizations/$ORG.example.com/users/$USER@$ORG.example.com/msp/keystore/priv_sk"
}

function tool_ski() {
    openssl pkey -in "$1" -pubout -outform DER | \
        dd ibs="26" skip=1 | \
        openssl dgst -sha256 | \
        cut -d ' ' -f2
}

function foundation_admin_base58() {
    if [ ! -f "organizations/admin_foundation.pem" ]; then
        openssl genpkey -algorithm ed25519 -outform PEM -out organizations/admin_foundation.pem
    fi

    key="$(openssl pkey -in "organizations/admin_foundation.pem" -pubout -outform DER | dd ibs="12" skip=1 | xxd -p -c 32)"
    encode58 $key
    echo    
}

function foundation_admin_base58check() {
    if [ ! -f "organizations/admin_foundation.pem" ]; then
        openssl genpkey -algorithm ed25519 -outform PEM -out organizations/admin_foundation.pem
    fi

    key="$(openssl pkey -in organizations/admin_foundation.pem -pubout -outform DER | dd ibs="12" skip=1 | openssl dgst -sha3-256 -binary | xxd -p -c 256)"
    encode58check $key
    echo
}

function encode58() {
    b58chars=123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz
    numHex=$1

    # remain leading 1 in base58
    prefix=''
    if test "00" == "$(echo -n $numHex | cut -c 1-2)"; then
        prefix=1
    fi

    numHex=$(echo -n $numHex | tr a-z A-Z)
    num58=''
    for charIndex in $(echo "obase=58;ibase=16;$numHex" | bc | tr -d '\n\\'); do
        num58=$num58$(echo -n $b58chars | cut -c $(( 10#$charIndex+1 )))
    done
    echo $prefix$num58
}

function encode58check() {
    local data=$1
    local checksum=$(echo -n "$data" | xxd -r -p | openssl dgst -sha256 -binary | openssl dgst -sha256 -binary | xxd -p -c 256 | head -c 8)
    local full_hex="${data}${checksum}"
    local base58str=$(encode58 "$full_hex")

    local leading_zeros=$(echo -n "$full_hex" | sed 's/\(00\)*.*/\1/' | sed 's/00/1/g')

    echo "${leading_zeros}${base58str}"
}

MODE=$1

# Determine mode of operation and printing out what we asked for
if [ "$MODE" == "robotSki" ]; then
  robotSki
elif [ "$MODE" == "backendSki" ]; then
  backendSki
elif [ "$MODE" == "adminValidator" ]; then
  adminValidator
elif [ "$MODE" == "adminAdress" ]; then
  adminAdress
else
  exit 1
fi
