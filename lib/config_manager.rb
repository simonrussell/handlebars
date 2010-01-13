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

class ConfigManager < Toolbase

  def update_alternatives(category, command)
    task "update alternative for #{category} to #{command}" do
      check "alternative for #{category} is #{command}" do
        shell "update-alternatives --list #{category} | pcregrep ^#{command}$"
      end
      
      execute do
        shell_or_die "update-alternatives --set #{category} #{command}"
      end
    end
  end
  
  def hostname(new_name)
    short_name = new_name[/^[^\.]+/]
    
    task "change hostname to #{new_name}" do
      check "hostname is #{new_name}" do
        shell "hostname" do |resultcode, output|
          output.strip == short_name
        end
      end
      
      execute do
        old_name = shell_or_die('hostname').strip
        hosts = File.read('/etc/hosts')
        
        File.open '/etc/hostname', 'w' do |f|
          f.puts(short_name)
        end
      
        shell_or_die "hostname -F /etc/hostname"        
      end
    end
    
    @server_context.file '/etc/hosts', :content => @server_context.template('hosts.erb', :name => new_name)
  end

end