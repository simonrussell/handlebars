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

package %w(apache2 apache2-mpm-prefork)

# get rid of the default site
misc.run '[ ! -e /etc/apache2/sites-enabled/*default ]' => 'a2dissite default && apache2ctl graceful'

# stub out the default status location
file '/etc/apache2/mods-available/status.conf', :content => template('apache2/status.conf.erb'), :after => 'apache2ctl graceful'

# include custom types
file '/etc/apache2/conf.d/types.conf', :content => template('apache2/types.conf.erb'), :after => 'apache2ctl graceful'

# configure the virtualhost conf
file '/etc/apache2/conf.d/virtualhost.conf', :content => "NameVirtualHost *:80\n", :after => 'apache2ctl graceful'
