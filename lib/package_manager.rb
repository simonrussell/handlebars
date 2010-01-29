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

class PackageManager < Toolbase

  def install(*names)
    names = names.flatten
    options = extract_options!(names)
    force = options.delete(:force) ? '--force-yes' : ''
    debconf = options.delete(:debconf)
    
    task "install packages #{names.join(', ')}", options do
      packages_installed = shell_or_die('dpkg -l')
      
      names.each do |name|
        check "package #{name} is installed" do
          packages_installed =~ /^ii +#{name} /
        end
      end

      execute do
        ENV['DEBCONF_DB_OVERRIDE'] = "File{#{debconf}}" if debconf
        ENV['DEBIAN_FRONTEND'] = 'noninteractive'
        shell_or_die "apt-get install --assume-yes #{force} #{names.join(' ')}"
        @packages_installed = nil
      end        
    end
  end
  
  alias :default :install

  def reboot_required?

    running_kernel = shell_or_die("uname -r").strip
    latest_kernel = File.basename(File.readlink("/vmlinuz")).sub(/^vmlinuz-/, '')

    log.info "checking if #{running_kernel} is latest kernel version" do
      if latest_kernel == running_kernel
        log.info :good, "You are running latest installed kernel. Reboot not required"
      else
        log.warning :bad, "You have a newer kernel (#{latest_kernel}) installed. Reboot required"
      end
    end

  end
    
end
