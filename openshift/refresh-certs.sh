#!/bin/bash

# Issue new certs
/root/.acme.sh/acme.sh --dns dns_aws --issue -d console.jlor.app
/root/.acme.sh/acme.sh --dns dns_aws --issue -d *.apps.jlor.app

# Install new router cert
#cat /root/.acme.sh/\*.apps.${DOMAIN}/\*.apps.${DOMAIN}.cer /root/.acme.sh/\*.apps.${DOMAIN}/\*.apps.${DOMAIN}.key /root/.acme.sh/\*.apps.${DOMAIN}/ca.cer > /root/.acme.sh/\*.apps.${DOMAIN}/router.pem
#oc secrets new router-certs tls.crt=/root/.acme.sh/\*.apps.${DOMAIN}/router.pem tls.key=/root/.acme.sh/\*.apps.${DOMAIN}/\*.apps.${DOMAIN}.key -o json --type='kubernetes.io/tls' --confirm | oc replace -f -

# Install new console / API cert
#
#

# Redeploy certs
ansible-playbook -i inventory.ini /root/openshift-ansible/playbooks/redeploy-certificates.yml
