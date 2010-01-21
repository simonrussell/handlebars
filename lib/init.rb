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

$: << File.dirname(__FILE__)

$HANDLEBARS_BASE = File.expand_path(File.join(File.dirname(__FILE__), '..'))
$APP_BASE = File.expand_path(File.join(File.dirname(__FILE__), '../..'))

begin
  require 'rubygems'
  require 'json'
  require 'mysql'
rescue LoadError
  # doesn't matter, they're not installed
end

begin
  require 'Win32/Console/ANSI' if PLATFORM =~ /win32/
rescue LoadError
  raise 'You must gem install win32console to use color on Windows'
end

require 'data_tools'

require 'fileutils'
require 'resolv'
require 'erb'
require 'yaml'

require 'erberizer'

require 'server_context'
require 'nice_logger'
require 'toolbase'
require 'package_manager'
require 'gem_manager'
require 'file_layout_manager'
require 'file_manager'
require 'directory_manager'
require 'config_manager'
require 'misc_manager'
require 'git_manager'
require 'auth_manager'
require 'mysql_manager'
require 'cron_manager'
require 'ohai_manager'
require 'iptables_manager'
require 'nfs_manager'

require 'server_list'

require 'mysql_connection'
require 'mysql_query'
require 'mysql_column'
