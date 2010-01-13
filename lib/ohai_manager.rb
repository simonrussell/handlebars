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

class OhaiManager < Toolbase
  
  def initialize(server_context, hash)
    super(server_context)
    
    @hash = hash
  end
  
  def lookup(*path)
    if path.length == 1 && path.first =~ /\//
      path = path.first.split('/')
    end
    
    result = self
    context = []
    
    while result && !path.empty?
      key = path.shift.to_s
      context << key
      raise "unknown ohai key #{context.join('/')}" unless result.key?(key)
      
      result = result[key]
    end
    
    result    
  end
  
  alias :default :lookup
    
  def keys
    @hash.keys
  end
  
  def key?(key)
    @hash.key?(key)
  end
  
  def [](key)
    result = @hash[key]
    
    result.is_a?(Hash) ? OhaiManager.new(@server_context, result) : result
  end
    
  def self.from_command(server_context)
    new(server_context, {}).send(:setup_from_command!)
  end
  
  def to_s
    "#<OhaiManager #{@hash.inspect}>"
  end
  
  private
  
  def setup_from_command!
    @hash = JSON.parse(shell_or_die("ohai -d #{File.join($APP_BASE, 'ohai')}"))
    
    self
  end
  
end