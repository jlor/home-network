#!/bin/bash

###
### Network settings

DOMAIN="tm234.lan"
IP_START="10.0.0"

### 
### Certificate Authority file paths

ROOT_KEY="aaboet.rootCA.key" # Secret key
ROOT_PEM="aaboet.rootCA.pem" # CA certificate

###
### Certificate details -- CN will be set further down
CERT_SUBJ="/C=DK/ST=Aarhus/L=Trige/O=Home Network/OU=Operations"

### That's it! Moving the cursor beyond this point breaks all warranties.

CERTNAME=$1
IP_EXT=$2

echo "Let's create some TRUST!"
echo
if [ -z "${CERTNAME}" ]; then
  read -p "Please provide a hostname: " CERTNAME
else
  echo "Certificate name: ${CERTNAME}"
fi

if [ -z "${IP_EXT}" ]; then
  read -p "Please provide the IP: ${IP_START}." IP_EXT
else
  echo "IP address: ${IP_START}.${IP_EXT}"
fi

echo
echo "Alrighty, let's begin!"
sleep 3

## Create key and create signing request for this key.
echo
CERT_SUBJ="${CERT_SUBJ}/CN=${CERTNAME}.${DOMAIN}"
openssl req -newkey rsa:4096 -nodes -subj "${CERT_SUBJ}" -keyout ${CERTNAME}.key -out ${CERTNAME}.csr &>/dev/null
if [[ -f ${CERTNAME}.key && -f ${CERTNAME}.csr ]]; then
  echo "** Key and signing request created!"
  sleep 3
else
  echo "!! Something went wrong :-(  ..bye"
  exit
fi

## Read that signing request and sign it
openssl x509 -req -extfile <(printf "subjectAltName=DNS:${CERTNAME}.${DOMAIN},IP:${IP_START}.${IP_EXT}") -days 365 -in ${CERTNAME}.csr -CA ${ROOT_PEM} -CAkey ${ROOT_KEY} -CAcreateserial -out ${CERTNAME}.crt &>/dev/null
if [ -f ${CERTNAME}.crt ]; then
  echo "** Certificate has been signed successfully!"
else
  echo "!! Something went wrong :-(  ..bye"
  exit
fi

## Pack it up
echo
tar czf ${CERTNAME}.tgz ${CERTNAME}.key ${CERTNAME}.csr ${CERTNAME}.crt
if tar -tf ${CERTNAME}.tgz ${CERTNAME}.key >/dev/null 2>&1; then
  rm ${CERTNAME}.{key,csr,crt}
  echo ":-)"
  echo "Signed certificate, key and signing request (why not) is at ${CERTNAME}.tgz" 
else
  echo ":-("
  echo ".tgz creation failed. These files have been left for you:"
  ls -l ${CERTNAME}*
fi
