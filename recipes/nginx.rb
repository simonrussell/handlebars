# add nginx repository to apt sources
file.line '/etc/apt/sources.list', "deb http://ppa.launchpad.net/jdub/devel/ubuntu hardy main", :after => 'apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E9EEF4A1 && apt-get update'

package %w(nginx), :after => '/etc/init.d/nginx start'
