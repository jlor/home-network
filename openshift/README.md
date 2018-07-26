# Openshift 3.9 + LetsEncrypt certificates
Heavily influenced by / copied from [Grant Shipley](https://github.com/gshipley/installcentos/).

This version adds support for LetsEncrypt certificates on Console/API server and routes.

Currently only AWS Route53 is supported, however it should be simple to change the install-openshift.sh script to allow for other integrations. See [acme.sh DNS API README.md](https://github.com/Neilpang/acme.sh/blob/master/dnsapi/README.md) and look for acme.sh in the install-openshift.sh script.

## Tested on
- CentOS-7-x86_64-Minimal-1804.iso installation
- 18Gb RAM
- 200Gb HDD (190Gb / partition)
- 4 CPU cores (20 pods/core)
- Using AWS Route53, with the domain setup already

The script will install logging if the system has > 8Gb memory and metrics if the system has > 4Gb memory.

## How to run
Log in to the OpenShift host as root

`curl -o install-openshift.sh https://raw.githubusercontent.com/jlor/home-network/master/openshift/install-openshift.sh && /bin/bash install-openshift.sh`

This will prompt you for information such as domainname, username, password and IP address.

## Automation
```
export DOMAIN=jlor.app
export USERNAME=jlor
export PASSWORD=jlor
export IP=a.b.c.d
export AWS_ACCESS_KEY_ID=AKIAxxxxxxxxxxxxxxx
export AWS_SECRET_ACCESS_KEY=<insert your key here>
curl https://raw.githubusercontent.com/jlor/home-network/master/openshift/install-openshift.sh | INTERACTIVE=false /bin/bash
```
## Todo
- Create and test a way to update certificates on API and routes (from `openshift-ansible` playbook: `redeploy_certificates.yaml`)
- Find out why the ansible script fails on Service Catalog Install during API server restart
- Test the script on Atomic Host
- Change large parts of the install-openshift.sh script to make use of ansible (software install, SSH keys, etc.)
- Update to OpenShift 3.10

## Notes
This project is a living project. I tear down my infrastructure often to try something new.
As a consequence this project tries to automate as much as possible. The hope is to create code-as-documentation and fire-and-forget scripts.
