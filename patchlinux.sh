#! /usr/bin/bash

#check the Linux Distribution and proceed only for fedora family systems
if ! grep -E "CentOS|centos|rhel|fedora|rocky" /etc/*-release ; then
    echo "Not a supported linux distribution, the current supported systems are rhel based"
    exit 1
fi

# Few troubleshooting steps

trb1() {
    # you get “rpmdb” error during EC2 instance patching, please find below steps to resolve the issue.  
    echo "Rebuilding RPM DB.."
    mv /var/lib/rpm/__db*  /tmp
    yum clean all
    rpm --rebuilddb
    yum update --security --bugfix --exclude=java* -y 
    rm -rf /tmp/__db*
}

trb2() {
    # Reconfiguring repo if there's an issue with older ones or if they aren't enabled at all 
    echo "Reconfiguring repos.."
    mv /etc/sysconfig/rhn /etc/sysconfig/rhnold
    cd /etc/yum.repos.d || exit 1
    # NOTE : yum.repos.d directory will be blank in most of the server but in some server it will have a file called "spacewalk-bootstrap.repo" , which can be deleted )
    rm -f *
    wget http://enghost.prod.ch3.s.com/~syseng/repo_aws/CentOS-Base.repo
    wget http://enghost.prod.ch3.s.com/~syseng/repo_aws/CentOS-CR.repo
    wget http://enghost.prod.ch3.s.com/~syseng/repo_aws/CentOS-Debuginfo.repo
    wget http://enghost.prod.ch3.s.com/~syseng/repo_aws/epel.repo
    yum clean all
    yum repolist
    puppet agent --disable
}

# The actual command
patchcommand1() {
    #yum update --security --bugfix --exclude=java* -y
    # Going with this because I've seen few instances where app teams configured their application repos for things like docker and K8s but are failing to load because of various reasons.
    # But this script should be able to choose one command from the following based on the os since we are going with different repositories in different environments.
    yum update --security --bugfix --exclude=java* --disablerepo=* --enablerepo=base,epel,extras,updates -y
}

patchcommand2() {
    # We use these repos in few systems
    yum update --security --bugfix --exclude=java* --disablerepo=* --enablerepo=CentOS-Base,CentOS-CR,CentOS-Debuginfo,epel -y
}


# Run the command and store the output into a variable
output_log=$patchcommand1

# Check if the update is successful
if [ $? -eq 0 ]; then
    echo "Update success, Following is the update log:"
    yum history info
else
    echo "Update failed, with the following reason:"
    echo "$output_log"
fi

