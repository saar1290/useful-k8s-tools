#! /bin/bash

RED="\e[91m"
GREEN="\e[92m"
NONE="\e[0m"

pfx=$1
private=$2
public=$3

if [ $# -ne 3 ]; then
    echo -e $RED"Missing arguments, please useage three arguments such as: pfx private public"$NONE
elif [ $# -eq 3 ]; then
    echo -e $GREEN"Extracting the private key $private --->"$NONE
    openssl pkcs12 -in $pfx -nocerts -out $private
    echo -e $GREEN"Extracting the public key $public --->"$NONE
    openssl pkcs12 -in $pfx -clcerts -nokeys -out $public
    echo -e $GREEN"Decrypting the private key --->"$NONE
    openssl rsa -in $private -out "${private}_no_pass.key"
fi

        