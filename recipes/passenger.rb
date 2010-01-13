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

cook 'apache2'
package %w(libopenssl-ruby apache2-prefork-dev libapr1-dev libaprutil1-dev)

PASSENGER_VERSION = '2.2.9'

gem 'passenger' => PASSENGER_VERSION

# include the following code in /etc/apache2/conf.d/passenger
# this is a hack that will stop working if passenger is upgraded past version 2.2.9
#   LoadModule passenger_module /usr/lib/ruby/gems/1.8/gems/passenger-2.2.9/ext/apache2/mod_passenger.so
#   PassengerRoot /usr/lib/ruby/gems/1.8/gems/passenger-2.2.9
#   PassengerRuby /usr/bin/ruby1.8

misc.install_passenger_for_apache2
file '/etc/apache2/mods-available/passenger.load', 
  :mode => '644', 
  :owner => 'root', 
  :group => 'root', 
  :content => template('passenger/passenger.load.erb', :passenger_root => "/usr/local/lib/ruby/gems/1.8/gems/passenger-#{PASSENGER_VERSION}")
  
file '/etc/apache2/mods-available/passenger.conf', 
  :mode => '644', 
  :owner => 'root', 
  :group => 'root', 
  :content => template('passenger/passenger.conf.erb', :passenger_root => "/usr/local/lib/ruby/gems/1.8/gems/passenger-#{PASSENGER_VERSION}", :ruby => '/usr/local/bin/ruby')
  
misc.run '[ -e /etc/apache2/mods-enabled/passenger.load ]' => 'a2enmod passenger && /etc/init.d/apache2 force-reload'

# this seems to be needed by our cap deploy:cold
directory '/usr/local/etc/rails', :owner => 'root', :group => 'root', :mode => '750'