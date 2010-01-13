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

class FileManager < FileLayoutManager
    
  def copy(source, destination)
    source = File.expand_path(source)
    destination = File.expand_path(destination)

    task "copy #{source} to #{destination}" do
      check "make sure #{destination} exists" do
        test_existence?(destination)
      end
      
      check "make sure #{source} exists" do
        test_existence?(source)
      end
      
      check "make sure #{destination} == #{source}" do
        read_file(source) == read_file(destination)
      end
      
      execute do
        fail!("can't copy, source doesn't exist properly") unless test_existence?(source)
        
        FileUtils.cp source, destination
      end
    end
  end  
  
  def line(name, string)
    name = File.join('/', name) unless name =~ /^~/
    name = File.expand_path(name)

    task "put #{string.inspect} in #{name}" do
      check "make sure #{string.inspect} is in #{name}" do
        content = read_file(name)
        content =~ /^#{Regexp.escape(string)}$/
      end
      
      execute do
        File.open name, 'a' do |f|
          f.puts string
        end
      end
    end
  end
  
  def put(source, destination, options = {})
    original_source = source

    source = File.expand_path(app_base_filename('files', source))
    destination = File.join('/', destination) unless destination =~ /^~/
    destination = File.expand_path(destination)
    
    task "put #{original_source} to #{destination}: #{options.inspect}" do      
      fail!("#{source}: source not found") unless File.file?(source)
      
      check "file at #{destination} == #{original_source}" do
        File.file?(destination) && File.read(destination) == File.read(source)
      end
      
      execute do
        FileUtils.cp source, destination
        
        shell_or_die options[:after] if options[:after]
      end
      
      set_options_on_file(destination, options)
    end
  end
  
  def ensure(*names)
    options = extract_options!(names)
    content = options.delete(:content)
    seed_content = options.delete(:seed_content)
    
    names.flatten.each do |name|
      name = File.expand_path(name)
      
      task "ensure file #{name}", options do
        check "#{name} exists and is a file" do
          File.file?(name)
        end
        
        if content
          check "file at #{name} has correct content" do
            read_file(name) == content
          end
        end
        
        execute do
          if !File.exist?(name)
            write_file(name, content || seed_content)     # always create it, even we don't have content
          elsif File.file?(name)
            write_file(name, content) if content
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
    File.file?(name)
  end
  
end