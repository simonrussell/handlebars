# Copyright (c) 2010 Tricycle I.T. Pty Ltd
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# 
# (from http://www.opensource.org/licenses/mit-license.php)

# YOU MUST HAVE SSH INSTALLED BEFORE THIS WILL WORK (OBVIOUSLY) AND A ROOT ACCOUNT
# sudo apt-get install -y ssh

require 'remote_server'

BLATMODE = ARGV.delete('--blat')
BASIC_BOOTSTRAP_MODE = ARGV.delete('--no-remote-run')

if ARGV.length < 2
  puts "usage is:"
  puts "bootstrap.rb <hostname> <password> [<username> [<server> [<mirror-url>]]] [--blat]"
  exit 1
end

options = {
  :hostname => ARGV[0],
  :password => ARGV[1],
  :username => ARGV[2],
  :server => ARGV[3],
  :mirror => (ARGV[4])
}

server = ServerList.read(options[:hostname])[options[:hostname]] || {}

options[:mirror] ||= server['mirror']
options[:server] ||= (server['server'] || options[:hostname])

RemoteServer.set_root_password(options[:server], options[:username], options[:password]) if options[:username] && options[:username] != 'root' && !BLATMODE

RemoteServer.connect(options[:server], 'root', options[:password]) do
  install_runtime_environment(options[:mirror] || 'http://mirror.internode.on.net/pub/ubuntu/ubuntu/') unless BLATMODE
  send_tarball
  
  unless BASIC_BOOTSTRAP_MODE
    run_bootstrap(options[:hostname])
    run_roles
  end
end
