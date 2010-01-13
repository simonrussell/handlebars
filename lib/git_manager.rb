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

class GitManager < Toolbase
  
  def clone(repository, destination)
    task "git clone #{repository} to #{destination}" do
      check "#{destination} exists" do
        File.directory?(destination)
      end
      
      check "#{destination} is a git repo" do
        git_repo?(destination)
      end
        
      if git_repo?(destination)
        check "#{destination} is unmodified" do
          shell "cd #{destination} && git status" do |result, output|
            output == "# On branch master\nnothing to commit (working directory clean)\n"
          end
        end
        
        check "#{destination} has a remote of #{repository}" do
          shell "cd #{destination} && git remote show origin" do |result, output|
            output =~ /^\s*(Push\s+)?URL\:\s+#{Regexp.escape(repository)}\s*$/
          end        
        end
      
        log.info "fetching"
        fetch(destination)
            
        check "#{destination} is up to date" do
          shell "cd #{destination} && git rev-list ..origin/master" do |result, output|
            output =~ /\A\s*\Z/
          end
        end
      end
      
      execute do
        # git status should complain about "not a repo" or say "no changes"
        # if repo exists:
        # - git remote show origin
        #   - check URL =~ URL: <repo>
        # - git pull
        
        # if repo doesn't exist, clone it
        
        if git_repo?(destination)
          log.info "merging"
          shell_or_die "cd #{destination} && git merge origin/master"
        else
          log.info "cloning"
          fail("#{destination} exists") if File.exist?(destination)
          shell_or_die "git clone #{repository} #{destination}"
        end
          
      end
    end
  end
  
  alias :default :clone
  
  private

  def fetch(repo)
    shell_or_die "cd #{repo} && git fetch"
  end
  
  def git_repo?(path)
    File.directory?(File.join(path, '.git'))
  end
  
end