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

class FileLayoutManager < Toolbase
  
  def symlink_move(source, destination, options = {})
    source = File.expand_path(source)
    destination = File.expand_path(destination)

    task "move #{source} to #{destination} and leave symlink", options do
      check "symlink exists at #{source}" do
        File.symlink?(source)
      end
      
      check "symlink at #{source} points to #{destination}" do
        shell "file #{source.inspect}" do |resultcode, output|
          output == "#{source}: symbolic link to `#{destination}'\n"
        end
      end

      check "#{destination} exists" do
        test_existence?(destination)
      end

      execute do
        FileUtils.mv(source, destination) if test_existence?(source) && !test_existence?(destination)      # nothing has happened
        File.symlink(destination, source) if !File.exist?(source) && test_existence?(destination)
      end
    end    
  end
  
  def symlink(link, destination, options = {})
    link = File.expand_path(link)
    destination = File.expand_path(destination)
    
    task "symlink #{link} to #{destination}", options do
      check "symlink exists at #{link}" do
        File.symlink?(link)
      end
      
      unless options[:accept_any_destination]
        check "#{destination} exists" do
          test_existence?(destination)
        end

        check "symlink at #{link} points to #{destination}" do
          shell "file #{link.inspect}" do |resultcode, output|
            output == "#{link}: symbolic link to `#{destination}'\n"
          end
        end
      end
            
      execute do
        fail!("can't symlink, destination doesn't exist properly") unless test_existence?(destination)
        fail!("link exists") if File.exist?(link)
        
        File.symlink(destination, link)
      end
    end
  end
  
  def move(source, destination, options = {})
    source = File.expand_path(source)
    destination = File.expand_path(destination)

    task "move #{source} to #{destination}", options do
      check "make sure #{destination} exists" do
        test_existence?(destination)
      end
      
      check "make sure nothing exists at #{source}" do
        !File.exist?(source)
      end
      
      execute do
        fail!("can't move, source doesn't exist properly") unless test_existence?(source)
        fail!("can't move, destination already exists") if File.exist?(destination)
        
        FileUtils.mv source, destination
      end
    end
  end  
  
  protected
  
  def test_existence?(name)
    File.exist?(name)
  end
  
  def set_options_on_file(name, options)
    desired_mode = file_mode(options[:mode])
    desired_owner = options[:owner]
    desired_group = options[:group]
    
    if desired_mode
      check "#{name} mode is #{desired_mode.to_s(8)}" do
        File.stat(name).mode & 0777 == desired_mode     # seems to have some high bit set
      end

      execute do
        File.chmod(desired_mode, name)
      end
    end  
    
    if desired_owner
      desired_owner_id = string_to_uid(desired_owner)
      
      
      check "#{name} owner is '#{desired_owner}'" do
        File.stat(name).uid == desired_owner_id
      end
      
      execute do
        File.chown(desired_owner_id, nil, name)
      end
    end  

    if desired_group
      desired_group_id = string_to_gid(desired_group)

      check "#{name} group is '#{desired_group}'" do
        File.stat(name).gid == desired_group_id
      end

      execute do
        File.chown(nil, desired_group_id, name)
      end
    end  
  end
  
  def file_mode(mode)
    mode.is_a?(String) ? mode.to_i(8) : mode
  end
  
  # TODO nicer this
  def string_to_uid(name)
    passwd = `getent passwd | pcregrep ^#{name}\:`
    
    $1.to_i if passwd =~ /^[^\:]+\:[^\:]+\:(\d+)/
  end
  
  # TODO nicer this
  def string_to_gid(name)
    passwd = `getent passwd | pcregrep ^#{name}\:`
    
    $1.to_i if passwd =~ /^[^\:]+\:[^\:]+\:[^\:]+\:(\d+)/
  end
  
end
