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

class DirectoryManager < FileLayoutManager
  
  def remove(*names)
    names.flatten.each do |name|
      task "remove directory #{name}" do
        check "#{name} doesn't exist" do
          !File.exist?(name)
        end
        
        execute do
          fail("#{name} isn't a directory") unless File.directory?(name)
          Dir.rmdir(name)
        end
      end
    end
  end
  
  def ensure(*names)
    options = extract_options!(names)
    
    names.flatten.each do |name|
      name = File.expand_path(name)
      
      task "ensure directory #{name}: #{options.inspect}" do
        check "#{name} exists and is a directory" do
          File.directory?(name)
        end
        
        execute do
          if !File.exist?(name)
            FileUtils.mkdir_p(name)
          elsif File.directory?(name)
            # nothing
          else
            fail!("can't create #{name}, something in the way")
          end
        end
        
        set_options_on_file(name, options)
      end
    end
  end
  
  alias :default :ensure

  protected
  
  def test_existence?(name)
    File.directory?(name)
  end
    
end