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

module DataTools

  # Data is never shared inside handlebars, so don't use app_base_filename here
  def read_data(filename)
    full_path = File.join($APP_BASE, 'data', filename)
    
    return '' unless File.exist?(full_path)
    
    File.read(full_path)
  end
  
  def read_data_kv(filename)
    data = read_data(filename)

    result = {}
    
    data.split("\n").each do |line|
      result[$1] = $2 if line.strip =~ /^([^\s]+)\s+(.+)$/
    end
    
    result
  end
  
  def read_data_kv_multi(filename)
    data = read_data(filename)

    result = {}
    
    data.split("\n").each do |line|
      if line.strip =~ /^([^\s]+)\s+(.+)$/
        result[$1] ||= []
        result[$1] << $2
      end
    end
    
    result
  end

  def append_data_kv(filename, key, value)
    File.open File.join($APP_BASE, 'data', filename), 'a' do |f|
      f.puts "#{key} #{value}"
    end
  end

  # FILES
    
  def local_file?(name)
    File.file?(app_base_filename('files', name))
  end

  # get the file from either handlebars, or the site dir -- site dir takes precedence; if file doesn't exist, return site name
  def app_base_filename(*name_parts)
    handlebars_name = File.join(*[$APP_BASE, 'handlebars', name_parts].flatten)
    site_name = File.join(*[$APP_BASE, name_parts].flatten)
    
    File.exist?(handlebars_name) && !File.exist?(site_name) ? handlebars_name : site_name
  end

  # SERVER STUFF
  
  def login_key(names)
    keys = read_data_kv('login_keys')

    # TODO convoluted, clean up
    names = [names] unless names.is_a?(Array)
    names = names.flatten

    names.map do |name|
      case name
      when :all_keys
        keys.values
      when Symbol
        login_key((keys[":#{name}"] || '').split)
      when /^\:/
        login_key((keys[name] || '').split)
      else
        keys[name]
      end
    end.flatten.uniq
  end
    
end
