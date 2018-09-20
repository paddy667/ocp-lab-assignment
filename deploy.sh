#!/bin/bash

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

set -o errexit

usage() {
	cat <<- EOF
  usage: $PROGNAME options
  
  This script is used to deploy an openshift cluster to AWS. 
  

  OPTIONS:
     -d --deploy          Deploy an Openshift instance to AWS
     -p --provision-only  Only create the infractructure in AWS. Nothing more.
     -s --setup-only      Only run setup on the hosts.
     -r --pre-req-only    Only run the openshift pre-reqs
     -c --cluster-only    Only run the cluster deployment
     -o --openshift-only  Only run the openshift configure playbook
     -z --decom           Decom the cluster
     -h --help            Display this help
  
  Examples:
     Run deployment:
     $PROGNAME --deploy

	EOF
}

cmdline() {
    # got this idea from here:
    # http://kirk.webfinish.com/2009/10/bash-shell-script-to-use-getopts-with-gnu-style-long-positional-parameters/
    local arg=
    for arg
    do
        local delim=""
        case "$arg" in
            #translate --gnu-long-options to -g (short options)
            --deploy)           args="${args}-d ";;
            --provision-only)   args="${args}-p ";;
            --setup-only)       args="${args}-s ";;
            --pre-req-only)     args="${args}-r ";;
            --cluster-only)     args="${args}-c ";;
            --openshift-only)   args="${args}-o ";;
            --decom)            args="${args}-z ";;
            --help)             args="${args}-h ";;
            #pass through anything else
            *) [[ "${arg:0:1}" == "-" ]] || delim="\""
                args="${args}${delim}${arg}${delim} ";;
        esac
    done

    #Reset the positional parameters to the short options
    eval set -- $args

    while getopts "dpsrchoz" OPTION
    do
         case $OPTION in
         d)
             readonly DEPLOY=true
             ;;
         p)
             readonly PROVISION=true
             ;;
         s)
             readonly SETUP=true
             ;;
         r)
             readonly PREREQ=true
             ;;
         c)
             readonly CLUSTER=true
             ;;
         o)
             readonly OPENSHIFT=true
             ;;
         z)
             readonly DECOM=true
             ;;
         h)
             usage
             exit 0
             ;;
        esac
    done

    return 0
}

provision(){
  ansible-playbook playbooks/provisioning/aws.yml
}

setup(){
  ansible-playbook playbooks/setup/setup.yml
}

pre-req(){
  ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml
}

deploy_cluster(){
  ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml
}

configure_openshift(){
  ansible-playbook playbooks/configure/configure.yml
}

decom(){
  ansible-playbook playbooks/decomissioning/aws.yml
}

main(){

  cmdline $ARGS

  if [[ $DEPLOY ]]; then 
    provision
    setup
    pre-req
    deploy_cluster
    configure_openshift
  elif [[ $PROVISION ]]; then
    provision
  elif [[ $SETUP ]]; then
    setup
  elif [[ $PREREQ ]]; then
    pre-req
  elif [[ $CLUSTER ]]; then
    deploy_cluster
  elif [[ $DECOM ]]; then
    decom
  elif [[ $OPENSHIFT ]]; then
    configure_openshift
  fi
}
main

