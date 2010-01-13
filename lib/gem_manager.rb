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

class GemManager < Toolbase
  
  def install(*names)
    names = flatten_to_hash(names)
    
    task "install gem #{human_gem_list(names)}" do
      gems_installed = shell_or_die('gem list -l')
      
      names.each do |name, version|
        check "gem #{name} is installed" do
          gems_installed =~ /^#{name} +\(/
        end
        
        unless version == true
          check "gem #{name} is #{version}" do
            gems_installed =~ /^#{name} +\(#{version}\)/
          end
        end
      end
              
      execute do
        needing_removal = names.map do |name, version|
          name if gems_installed =~ /^#{name} +\(/ && gems_installed !~ /^#{name} +\(#{version}\)/
        end.compact
        
        unless needing_removal.empty?
          log.info "removing #{needing_removal.join(', ')}"
          shell_or_die "gem uninstall -I -a -x #{needing_removal.join(' ')}"
        end
        
        gems_installed = shell_or_die('gem list -l')
        
        needing_install = {}        
        names.each do |name, version| 
          needing_install[name] = version unless gems_installed =~ /^#{name} +\(/
        end
        
        needing_install.each do |name, version|
          log.info "installing #{human_gem_list(name => version)}"
          shell_or_die "gem install #{name} #{"--version #{version}" unless version == true} --no-ri --no-rdoc"
        end
      end
    end
  end
  
  alias :default :install
  
  private
  
  def flatten_to_hash(names)
    result = {}
    
    names.flatten.each do |name|
      if name.is_a?(Hash)
        result.merge!(name)
      else
        result[name] = true
      end
    end
    
    result
  end
  
  def human_gem_list(names)
    names.map { |name, version| version == true ? name : "#{name} #{version}" }.join(', ')
  end
  
end