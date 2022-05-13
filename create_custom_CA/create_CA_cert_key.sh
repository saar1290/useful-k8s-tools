#! /bin/bash

cert_CA="ca.pem"
key_CA="./ca.key"

openssl genrsa -des3 -out $key_CA 2048                                                                                  

read -p "Enter your Country Name: " C
read -p "Enter your State or Province Name: " ST
read -p "Enter your Locality Name: " L
read -p "Enter your Organization Name: " O
read -p "Enter your Organizational Unit Name: " OU

openssl req -x509 -new -nodes -key $key_CA -subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=Root CA" -sha256 -days 3650 -out $cert_CA
