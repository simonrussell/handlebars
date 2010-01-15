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

class AuthManager < Toolbase
  
  def uids
    @uids ||= read_data_kv('uids')
  end
  
  def predefined_shadows
    @predefined_shadows ||= read_data_kv('shadows')
  end
  
  def user(name, options = {})
    options[:uid] ||= uids[name]
    options[:gid] ||= options[:uid]
    options[:shadow] ||= predefined_shadows[name]
    options[:timezone] ||= 'UTC'
    
    login_keys = login_key(options.delete(:login_keys) || [])
    shadow = options.delete(:shadow)
    
    task "user #{name}: #{options.inspect}" do
      check "user exists, and has matching options" do
        
        passwd =~ make_passwd_matcher(
          name,
          nil,
          options[:uid],
          options[:gid],
          nil,
          nil,
          options[:shell]
        )
      end
      
      execute do
        if user_exists?(name)
          old_options = user_options(name)
          options = old_options.merge(options)
          
          shell_or_die "userdel #{name}"
          shell_or_die "find / -wholename '/proc' -prune -o -wholename '/dev' -prune -o -group #{old_options[:gid]} -print0 | xargs -r -0 chgrp #{options[:gid]}"
          shell_or_die "find / -wholename '/proc' -prune -o -wholename '/dev' -prune -o -user  #{old_options[:uid]} -print0 | xargs -r -0 chown #{options[:uid]}"
        end

        options[:shell] ||= '/bin/bash'
        
        command_options = options.map do |k, v|
          next if v.nil?
          
          case k
          when :uid
            "--uid #{v}"
          when :gid
            "--gid #{v}" unless v == options[:uid]
          when :full_name
            "--comment #{v.inspect}"
          when :home
            "-m #{"--home-dir #{v.inspect}" unless v == true}"
          when :shell
            "--shell #{v.inspect}"
          when :sudoer
            # nothing, dealt with later
          when :timezone
            # nothing, dealt with later
          else
            fail! "#{k}: unknown useradd option"
          end
        end
    
        shell_or_die "useradd #{command_options.join(' ')} #{name}"
      end
    end
    
    if options[:sudoer]
      @server_context.file.line '/etc/sudoers', (options[:sudoer] == true ? "#{name} ALL=(ALL) ALL" : "#{name} #{options[:sudoer]}")
    end
    
    if options[:home]
      timezone_line = "export TZ=/usr/share/zoneinfo/#{timezone}"
      @server_context.file.line "#{home}/.bashrc", timezone_line
    end

    unless login_keys.empty?
      @server_context.directory "~#{name}", :owner => name, :group => name, :mode => '755'
      @server_context.directory "~#{name}/.ssh", :owner => name, :group => name, :mode => '700'
      @server_context.file "~#{name}/.ssh/authorized_keys", :owner => name, :group => name, :mode => '600', :content => login_keys.join("\n")
    end
    
    password_shadow(name, shadow) if shadow
    
    ssh_key(name, "#{name}/id_rsa") if local_file?("ssh/#{name}/id_rsa")
    ssh_key(name, "#{name}/id_dsa") if local_file?("ssh/#{name}/id_dsa")
  end
  
  def group(name, options = {})
    
  end
  
  def password_shadow(user, shadow)
    task "set login password for #{user}" do
      check "login password for #{user} is correct" do
        shadow_file =~ /^#{Regexp.escape(user)}\:#{Regexp.escape(shadow)}\:/
      end
      
      execute do
        current_shadow = shadow_file
        
        File.open '/etc/shadow', 'w' do |f|
          f.write current_shadow.gsub(/^#{Regexp.escape(user)}\:[^\:]\:/, "#{user}:#{shadow}:")
        end
      end
    end
  end
  
  def ssh_key(user_name, key_name)
    @server_context.instance_eval do
      group "add ssh key #{key_name} to #{user_name}" do
        directory "~#{user_name}/.ssh", :owner => user_name, :group => user_name, :mode => '755'
        file.put "ssh/#{key_name}", "~#{user_name}/.ssh/#{File.basename(key_name)}", :owner => user_name, :group => user_name, :mode => '600'
        file.put "ssh/#{key_name}.pub", "~#{user_name}/.ssh/#{File.basename(key_name)}.pub", :owner => user_name, :group => user_name, :mode => '644'
      end
    end
  end
  
  def ssh_known_host(host_name, options = {})
    built_in_keys = read_data_kv_multi('host_keys')[host_name]
    
    @server_context.instance_eval do
      group "add known host entry for #{host_name}" do
        keys = ([options[:key]] | (options[:keys] || []) | built_in_keys).compact
        ip_address = options[:ip_address] || (host_name && Resolv.getaddress(host_name))
        
        file '/etc/ssh/ssh_known_hosts', :mode => '440', :owner => 'root', :group => 'root'

        keys.each do |key|
          host_line = "#{host_name},#{ip_address} #{key}"
          file.line '/etc/ssh/ssh_known_hosts', host_line
        end
      end
    end
  end


  
  private
  
  def user_exists?(name)
    !!user_options(name)
  end
  
  def user_options(name)
    fields = (passwd =~ /^(#{Regexp.escape(name)}\:.*)/ && $1.split(':'))
     
    if fields
      {
        :uid => fields[2],
        :gid => fields[3],
        :full_name => fields[4],
        :home => fields[5],
        :shell => fields[6]
      }
    end
  end
  
  # 0    1        2   3   4        5    6
  # user:password:uid:gid:fullname:home:shell
  def make_passwd_matcher(*spec)
    /^(#{spec.map { |i| i.nil? ? '[^\:]*' : Regexp.escape(i.to_s) }.join('):(')})/
  end
  
  def passwd
    File.read('/etc/passwd')
  end
  
  def shadow_file
    File.read('/etc/shadow')
  end
  
end
