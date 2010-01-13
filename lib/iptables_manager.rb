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

class IptablesManager < Toolbase
  
  IPTABLES_CONFIG_PATH = '/usr/local/sbin/firewall.sh'

  def config(command_lines)
    @firewall_config ||= "#!/bin/bash\n/sbin/iptables --flush\n/sbin/iptables -X\n"

    log.info "iptables" do
      command_lines.gsub(/\s*#.*$/, '').split("\n").each do |command_line|
        next if command_line =~ /^\s*$/
        
        command_line = "/sbin/iptables #{command_line.strip}\n"
          
        log.info command_line.strip
        @firewall_config << command_line
      end
    end
  end
  
  alias :default :config
  
  def finish_cooking
    firewall_config = @firewall_config    # because of the scope of the block below
    
    @server_context.instance_eval do
      file.line '/etc/rc.local', IPTABLES_CONFIG_PATH
      file IPTABLES_CONFIG_PATH, 
        :owner => 'root', 
        :group => 'root', 
        :mode => '700', 
        :content => (firewall_config || "#!/bin/bash\n/sbin/iptables --flush\n/sbin/iptables -X\n"),  # stub file
        :after => IPTABLES_CONFIG_PATH   
    end
  end
    
end