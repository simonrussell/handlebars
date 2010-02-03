package %w(mysql-server libmysqlclient15-dev)
gem %(mysql)

# move it to a place we like
mysql.datadir '/srv/mysql'

# set the root password, clean up the users
mysql.admin_password
file '/etc/mysql/password.root', :owner => 'root', :group => 'root', :mode => '600', :content => password_db('mysql/user/root')
mysql.cleanup_users

file.put 'my.cnf', '/etc/mysql/my.cnf', :after => '/etc/init.d/mysql restart'

#iptables %(
#  -N mysql                                      # create a chain for mysql
#  -A mysql -j LOG --log-level 7                 # log everything
#  -A mysql -j DROP                              # drop everything!
#
#  -A INPUT -p tcp --dport 3306 -g mysql         # jump to the mysql chain if tcp and port 3306
#  -A INPUT -p udp --dport 3306 -g mysql         # jump to the mysql chain if tcp and port 3306
#)
