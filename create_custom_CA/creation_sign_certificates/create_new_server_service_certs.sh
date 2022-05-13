#! /bin/bash
read -p "Name of your server or service and hit ENTER:" name
read -p "Number of days expire:" days

cert="./certs/$name.crt"
key="./private/$name.key"
csr="./CAsign/$name.csr"
ca="../ca.pem"
cakey="../ca.key"

if [ ! -d "./certs" ]
then
	echo "certs directory NOT exists, create one"
	mkdir certs
else
	echo "certs directory exists"
fi

if [ ! -d "./private" ]
then
	echo "private directory NOT exists, create one"
	mkdir private
else
	echo "private directory exists"
fi

if [ ! -d "./CAsign" ]
then
	echo "CAsign directory NOT exists, create one"
	mkdir CAsign
else
	echo "CAsign directory exists"
fi

if [ ! -f "./CAsign/v3.ext" ]
then
	echo "V3.ext file NOT exists, create one"
	read -p "Enter your domain: " domain
	read -p "Enter your FQDN: " FQDN
	read -p "Enter your Common name (CN):" CN
cat <<EOF> ./CAsign/v3.ext
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $domain
DNS.2 = $FQDN
DNS.3 = $CN
EOF
else
	echo "V3.ext file exists"
	read -p "Enter your domain: " domain
	read -p "Enter your FQDN: " FQDN
	read -p "Enter your Common name (CN):" CN
cat <<EOF> ./CAsign/v3.ext
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $domain
DNS.2 = $FQDN
DNS.3 = $CN
EOF
fi

openssl genrsa -out $key 2048
read -p "Enter your Country Name: " C
read -p "Enter your State or Province Name: " ST
read -p "Enter your Locality Name: " L
read -p "Enter your Organization Name: " O
read -p "Enter your Organizational Unit Name: " OU
read -p "Enter your Common Name: " CN
openssl req -new -key $key -subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$CN" -out $csr
openssl x509 -req -in $csr -CA $ca -CAkey $cakey -CAcreateserial -out $cert -days $days -sha256 -extfile ./CAsign/v3.ext
openssl verify -CAfile $ca $cert

ls -al $cert
ls -al $key
echo "Your SSL Certificate created sucssesfully and Signed"
