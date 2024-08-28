#!/bin/sh

# Install puppet
sudo rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm
sudo yum install -y puppet

# Show puppet master
echo '192.168.0.1 puppet' | sudo tee --append /etc/hosts

# Request a certificate and apply changes for the first time
sudo puppet agent -t --verbose --waitforcert 5 --onetime

# Add puppet to startup
sudo chkconfig puppet on

# Start puppet service
sudo service puppet start