# Tested on
- CentOS-7-x86_64-Minimal-1804.iso installation
- 18Gb RAM
- 200Gb HDD (190Gb / partition)
- 4 CPU cores (20 pods/core)
- Using AWS Route53, with the domain setup already

# How to run
Log in to the OpenShift host as root
`curl https://raw.githubusercontent.com/jlor/home-network/master/openshift/install-openshift.sh | /bin/bash`
This will prompt you for information such as domainname, username, password and IP address.

# Automation
```
export DOMAIN=jlor.app
export USERNAME=jlor
export PASSWORD=jlor
export IP=a.b.c.d
export AWS_ACCESS_KEY=AKIAxxxxxxxxxxxxxxx
export AWS_SECRET_ACCESS_KEY=<insert your key here>
curl https://raw.githubusercontent.com/jlor/home-network/master/openshift/install-openshift.sh | INTERACTIVE=false /bin/bash
```
