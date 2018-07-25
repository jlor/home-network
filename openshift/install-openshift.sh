#!/bin/bash

##
# Heavily inspired by https://github.com/gshipley/installcentos
# Modified to include LetsEncrypt/ACME.sh by Jakob Rosenlund
#

# Setup variables with default values
export DOMAIN=${DOMAIN:="$(curl -s ipinfo.io/ip).nip.io"}
export IP=${IP:="$(hostname -I)"}
export USERNAME=${USERNAME:="$(whoami)"}
export PASSWORD=${PASSWORD:="$(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c${1:-10}; echo;)"}
export SCRIPT_REPO=${SCRIPT_REPO:="https://raw.githubusercontent.com/jlor/home-network/master/openshift/"}
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:=""}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:=""}
export INTERACTIVE=${INTERACTIVE:="true"}

# Give us our three finger claw
shout() { echo "$0: $*" >&2; }
die() { shout "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

if [[ "$INTERACTIVE" = "true" ]] ; then
    read -e -p "Domain: " -i $DOMAIN choice
    if [[ "$choice" != "" ]] ; then
        export DOMAIN="$choice"
    fi

    read -e -p "IP: " -i $IP choice;
    if [[ "$choice" != "" ]] ; then
        export IP="$choice";
    fi

    read -e -p "Username: " -i $USERNAME choice;
    if [[ "$choice" != "" ]] ; then
        export USERNAME="$choice";
    fi

    read -e -p "Password: " -i $PASSWORD choice;
    if [[ "$choice" != "" ]] ; then
        export PASSWORD="$choice";
    fi

    read -e -p "AWS_ACCESS_KEY_ID: " choice;
    if [[ "$choice" != "" ]] ; then
        export AWS_ACCESS_KEY_ID="$choice";
    fi

    read -e -p "AWS_SECRET_ACCESS_KEY: " choice;
    if [[ "$choice" != "" ]] ; then
        export AWS_SECRET_ACCESS_KEY="$choice";
    fi

    echo
fi

shout "==========================================================="
shout "== Domain: ${DOMAIN}"
shout "== IP: ${IP}"
shout "== Username: ${USERNAME}"
shout "== Password: ${PASSWORD}"
shout ""
shout "== AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}"
shout "== AWS_SECRET_ACCESS_KEY (last 4): ${AWS_SECRET_ACCESS_KEY: -4}"
shout "==========================================================="

if ! [ -x "$(command -v yum)" ]; then
    echo
    die "yum is not installed. Is this RHEL/CentOS?"
fi

# Update repo / system
yum update -y
# Install dependencies
yum install -y git docker net-tools wget zile nano bind-utils uptables-services bridge-utils bash-completion\
        kexec-tools sos psacct openssl-devel httpd-tools NetworkManager python-cryptography python2-pip\
        python-devel python-passlib java-1.8.0-openjdk-headline "@Development Tools"

# add EPEL repo and disable by default
yum -y install epel-release
sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo

# Make sure NetworkManager is running to provide DNS
systemctl | grep "NetworkManager.*running"
if [ $? -eq 1 ]; then
    systemctl start NetworkManager
    systemctl enable NetworkManager
fi

# Install Ansible+pyOpenSSL from EPEL repo
yum -y --enablerepo=epel install ansible pyOpenSSL

# Get Openshift-Ansible git repo -- for now limited to version 3.9
[ ! -d openshift-ansible ] && git clone --single-branch -b release-3.9 https://github.com/openshift/openshift-ansible.git
# install ACME.sh
curl https://get.acme.sh | sh

# Make sure AWS is setup
if [ "$AWS_ACCESS_KEY_ID" = "" ] || [ "$AWS_SECRET_ACCESS_KEY" = ""]; then
    die "Missing AWS access key and/or secret access key"
fi

# Get console.${DOMAIN} and *.apps.${DOMAIN} certs
/root/.acme.sh/acme.sh --issue -d console.${DOMAIN} --dns dns_aws
/root/.acme.sh/acme.sh --issue -d *.apps.${DOMAIN} --dns dns_aws

# Setup automatic refrehs of certs every 60 days
curl -o /tmp/refresh-openshift-cert.tmp $SCRIPT_REPO/refresh-openshift-cert.sh
envsubst < /tmp/refresh-openshift-cert.tmp > /root/refresh-openshift-cert.sh
chmod +x /root/refresh-openshift-cert.sh
grep 'refresh-openshift-cert.sh' /etc/crontab || echo "0 0 */60 * * /root/refresh-openshift-cert.sh" >> /etc/crontab

# Setup /etc/hosts
cat <<EOD > /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
${IP}       $(hostname) console console.${DOMAIN}
EOD

# Make sure docker is running
systemctl restart docker
systemctl enable docker

# Setup, copy SSH keys to root of the IP address and test
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -q -f ~/.ssh/id_rsa -N ""
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
    ssh -o StrictHostKeyChecking=no root@$IP "pwd" < /dev/null
fi

# Default install Metrics+Logging.
export METRICS="True"
export LOGGING="True"

# If memory < 4Gb , don't install metrics
memory=$(cat /proc/meminfo | grep MemTotal | sed "s/MemTotal:[ ]*\([0-9]*\) kB/\1/")
if [ "$memory" -lt "4194304" ]; then
    export METRICS="False"
fi

# If memory < 8Gb , don't install logging
if [ "$memory" -lt "8388608" ]; then
    export LOGGING="False"
fi

# Get Inventory file and substitute variables
curl -o inventory.tmp $SCRIPT_REPO/inventory.ini
envsubst < inventory.tmp > inventory.ini

# Install Openshift!
try ansible-playbook -i inventory.ini openshift-ansible/playbooks/prerequisites.yml
try ansible-playbook -i inventory.ini openshift-ansible/playbooks/deploy_cluster.yml

# Setup PATH so root can see oc CLI
export PATH=$PATH:/usr/local/bin

# Setup user
htpasswd -b /etc/origin/master/htpasswd ${USERNAME} ${PASSWORD}
oc adm policy add-cluster-role-to-user cluster-admin ${USERNAME}

# Restart OpenShift
systemctl restart origin-master-api

# Setup simple PVs
curl $SCRIPT_REPO/vol.yaml
for i in `seq 1 200`;
do
    DIRNAME="vol$i"
    mkdir -p /mnt/data/$DIRNAME
    chcon -Rt svirt_sandbox_file_t /mnt/data/$DIRNAME
    chmod 777 /mnt/data/$DIRNAME

    sed "s/name: vol/name: vol$i/g" vol.yaml > oc_vol.yaml
    sed -i "s/path: \/mnt\/data\/vol/path: \/mnt\/data\/vol$i/g" oc_vol.yaml
    oc create -f oc_vol.yaml
    echo "Created volume $i.."
done
rm oc_vol.yaml
rm vol.yaml
rm inventory.ini

echo
echo "===========================================================\n"
echo "* Console: https://console.$DOMAIN:8443"
echo "* Username: $USERNAME"
echo "* Password: $PASSWORD"
echo "*"
echo "* Logging in using:"
echo "$ oc login -u ${USERNAME} -p ${PASSWORD} https://console.$DOMAIN:8443/"

oc login -u ${USERNAME} -p ${PASSWORD} https://console.$DOMAIN:8443/
