package %w(build-essential git-core)
gem %w(json ohai)

package %w(mysql-client libmysqlclient15-dev)     # REE needs these for the mysql gem to work

config.hostname hostname
