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

require 'net/ssh'
require 'net/sftp'
require 'tempfile'

class RemoteServer
  include DataTools
  
  attr_reader :ssh
  
  def initialize(ssh)
    @ssh = ssh
  end
  
  def log
    @log ||= NiceLogger.new
  end
  
  def find_password(key)
    passwords = read_data_kv('password-db')
    
    if passwords.key?(key)
      passwords[key]
    else
      pwgen_result = exec_command('pwgen -1 -c 20 1')
      
      raise "pwgen didn't succeed" unless pwgen_result.first
      
      new_password = pwgen_result[1].strip
      append_data_kv('password-db', key, new_password)
      
      new_password
    end
  end
  
  def exec_command(command, show = false)
    output = ""
    
    @ssh.exec!("(#{command}) && echo SUCCESS || echo FAILURE $?") do |ch, stream, data|
      if data =~ ServerContext::PASSWORD_PROMPT_REGEX
        log.stream data.gsub(ServerContext::PASSWORD_PROMPT_REGEX, '')
        
        ch.send_data "#{find_password($1)}\n"
      else
        #$stdout.write data if show
        log.stream data if show
        
        output << data
      end
    end
    
    log.info if show
    
    if output =~ /\A(.*)(SUCCESS|FAILURE)( \d+)?\n\Z/m
      result = [$2 == 'SUCCESS', $1, $3.to_i]
    else
      raise "weird #{output.inspect}"
    end
    
    block_given? ? yield(result) : result
  end
  
  def get_environment(var)
    @ssh.exec!("echo $#{var}").strip
  end
  
  def upload_template(source_template, destination, options = {})
    Tempfile.open(File.basename(source_template)) do |f|
      f.write Erberizer.file(File.join($APP_BASE, 'handlebars', source_template), options)
      f.flush
          
      @ssh.sftp.upload!(f.path, destination)
    end  
  end
  
  def self.connect(host, user, password, &block)
    puts "Connecting to #{host} as #{user}..."
    Net::SSH.start(host, user, :password => password) do |ssh|
      server = new(ssh)
      
      server.instance_eval(&block)
    end
  end
  
  def self.set_root_password(host, username, password)
    connect(host, username, password) do
      log.info "set root password" do
        ssh.exec! "sudo passwd root" do |ch, stream, data|
          if data =~ /password for #{username}\:/ || data =~ /(Enter|Retype) new UNIX password\:/
            ch.send_data("#{password}\n")
          elsif data =~ /password updated successfully/
            log.info :good, "  password changed."
          else
            unless data =~ /\A\s*\Z/
              log.error data
              exit 1
            end
          end
        end
      end
    end
  end
  
  def install_runtime_environment(mirror)
    log.info "install runtime environment" do
      log.info "setup sources.list for #{mirror}"
      upload_template 'templates/sources.list.erb', '/etc/apt/sources.list', :mirror => mirror
    
      log.info "apt-get update" do
        exec_command 'apt-get update -y', true
      end
      
      log.info 'install ruby enterprise edition' do
        architecture = exec_command('uname -m')[1].strip
        # http://rubyforge.org/frs/download.php/68718/ruby-enterprise_1.8.7-2010.01_i386.deb
        # http://rubyforge.org/frs/download.php/68720/ruby-enterprise_1.8.7-2010.01_amd64.deb
        filename = "ruby-enterprise_1.8.7-2010.01_#{architecture == 'x86_64' ? 'amd64' : 'i386'}.deb"

        log.info "downloading #{filename}"
        exec_command "cd /tmp && [ ! -e #{filename} ] && wget -nv http://rubyforge.org/frs/download.php/#{architecture == 'x86_64' ? '68720' : '68718'}/#{filename}"
        
        log.info 'installing package'
        exec_command "dpkg -i /tmp/#{filename}"
        
        log.info 'symlinking /usr/bin/{ruby|gem} -> /usr/local/bin/{ruby|gem}'
        exec_command 'ln -s /usr/local/bin/ruby /usr/bin/ruby'
        exec_command 'ln -s /usr/local/bin/ruby /usr/bin/ruby'
      end
      
      log.info "install other packages" do
        exec_command 'apt-get install -y pcregrep pwgen', true
      end
    end
  end  
  
  def send_tarball
    log.info "tarball" do    
      log.info "creating"
      
      if File.exist?('c:\\cygwin\\bin')
        `c:\\cygwin\\bin\\tar cf server-bootstrap.tar --exclude=data/password-db *`
        `c:\\cygwin\\bin\\gzip server-bootstrap.tar`
      else
        `tar czf server-bootstrap.tar.gz --exclude=data/password-db *`
      end
      
      log.info "uploading"
      ssh.sftp.upload! "server-bootstrap.tar.gz", "/root/server-bootstrap.tar.gz"
      
      log.info "cleaning up"
      File.delete('server-bootstrap.tar.gz')
    
      log.info "decompressing"
      exec_command 'rm -Rf /root/server-bootstrap && mkdir /root/server-bootstrap && cd /root/server-bootstrap && tar xvf ../server-bootstrap.tar.gz'
    end  
  end
  
  def run_bootstrap(hostname)
    log.info "run server side bootstrap" do
      exec_command "cd /root/server-bootstrap && ./hb run bootstrap --hostname=#{hostname}", true
    end
  end
  
  def run_roles(*recipes)
    log.info "run role recipes" do
      exec_command "cd /root/server-bootstrap && ./hb run #{recipes.flatten.join(' ')}", true
    end    
  end
  
end
