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

class NiceLogger
  
  def initialize
    @indent = 0
  end
  
  def indent
    @indent += 2
  end
  
  def outdent
    @indent -= 2
    @indent = 0 if @indent < 0
  end
  
  def info(*args)
    if args.empty?
      puts
    elsif args.length == 2
      message = args.last
      style = case args.first
      when :good
        32
      when :bad
        31
      when :maybe
        33
      else
        raise "unknown style #{args.first}"
      end
    elsif args.length == 1
      message = args.first
      style = 0
    else
      raise "don't know how to log #{args.inspect}"
    end
    
    puts_indent "\e[#{style}m#{message}\e[0m#{" \e[1m{\e[0m" if block_given?}"

    if block_given?
      begin
        indent
        yield
      ensure
        outdent
        puts_indent "\e[1m}\e[0m"
      end
    end
  end
  
  def null(message)
    # nothing much
    yield if block_given?
  end
  
  alias :debug :null
  alias :warning :info
  alias :error :info
  alias :fatal :info
  
  def stream(text)
    $stdout.write text.gsub("\n", "\n#{" " * @indent}")
  end
  
  private
  
  def puts_indent(message)
    puts "#{" " * @indent}#{message}"
    $stdout.flush
  end
  
end