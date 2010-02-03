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

|app_name, rails_environment, canonical_host, aliases|

user_name = "#{app_name}_#{rails_environment}"
db_user_name = user_name[0...16]      # stupid mysql
secure = local_file?("ssl_cert/#{user_name}/#{user_name}.crt")
cap_root = File.join('/srv/www', user_name)

alias_list = aliases.keys
alias_without_redirect_list = aliases.reject { |name, do_redirect| do_redirect }.keys

cook %w(base passenger)

auth.user user_name, :sudoer => true, :home => true, :login_keys => :all

directory cap_root, File.join(cap_root, 'releases'), File.join(cap_root, 'shared'), File.join(cap_root, 'shared/pids'),
  :mode => '755',
  :owner => user_name,
  :group => user_name

directory File.join(cap_root, 'shared/log'),
  :mode => '777',
  :owner => user_name,
  :group => user_name

misc.run '[ -e /etc/apache2/mods-enabled/rewrite.load ]' => 'a2enmod rewrite && apache2ctl graceful'

file "/etc/apache2/sites-available/#{user_name}",
  :owner => 'root',
  :group => 'root',
  :mode => '644',
  :content =>
    template(
      'rails/apache-site.erb',
      :canonical_host => canonical_host,
      :aliases => alias_list,
      :aliases_without_redirect => alias_without_redirect_list,
      :cap_root => cap_root,
      :environment => rails_environment
    ),
  :after => 'apache2ctl graceful'

file File.join(cap_root, 'shared/database.yml'),
  :owner => user_name,
  :group => user_name,
  :mode => '644',
  :content => template('rails/database.yml.erb', :username => db_user_name, :password => password_db("mysql/user/#{db_user_name}"), :environment => rails_environment, :host => ip_by_role("#{app_name}/#{rails_environment}/db")),
  :after => "[ -e #{File.join(cap_root, 'current/tmp/')} ] && touch #{File.join(cap_root, 'current/tmp/restart.txt')} || true"

misc.run "[ -e /etc/apache2/sites-enabled/#{user_name} ]" => "a2ensite #{user_name} && apache2ctl graceful"

if secure
  misc.run '[ -e /etc/apache2/mods-enabled/ssl.load ]' => 'a2enmod ssl && apache2ctl graceful'

  directory '/etc/apache2/ssl',
    :owner => 'www-data',
    :group => 'www-data',
    :mode => '700'

  %w(crt key csr).each do |extension|
    file.put "ssl_cert/#{user_name}/#{user_name}.#{extension}", "/etc/apache2/ssl/#{user_name}.#{extension}",
      :owner => 'www-data',
      :group => 'www-data',
      :mode => '400'
  end

  file "/etc/apache2/sites-available/#{user_name}-ssl",
    :owner => 'root',
    :group => 'root',
    :mode => '644',
    :content =>
      template(
        'rails/apache-site.erb',
        :canonical_host => canonical_host,
        :aliases => alias_list,
        :aliases_without_redirect => alias_without_redirect_list,
        :cap_root => cap_root,
        :environment => rails_environment,
        :certificate => user_name
      ),
    :after => 'apache2ctl graceful'

  misc.run "[ -e /etc/apache2/sites-enabled/#{user_name}-ssl ]" => "a2ensite #{user_name}-ssl && apache2ctl graceful"
end
