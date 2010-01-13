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

class Toolbase
  include DataTools
  
  COMMAND_PREFIX = (RUBY_PLATFORM =~ /-mswin32$/ ? 'cmd /c ' : '')
  
  def initialize(server_context)
    @server_context = server_context
    @executing = true
  end
  
  protected

  def password_db(name)
    @server_context.password_db(name)
  end

  def read_file(name, default = nil)
    File.exist?(name) ? File.read(name) : default
  end
  
  def write_file(name, content)
    File.open name, 'w' do |f|
      f.write(content || '')
    end
  end
  
  def log
    @server_context.log
  end
  
  def extract_options!(args, default_options = {})
    if args.last.is_a?(Hash)
      args.pop
    else
      default_options
    end
  end
  
  def shell(command)    
    log.debug "--- SHELL: #{command}"

    result = `#{COMMAND_PREFIX}#{command}`
    
    block_given? ? yield($?, result) : $? == 0
  end
  
  def shell_or_die(command)
    log.debug "--- SHELL: #{command}"

    message = `#{COMMAND_PREFIX}#{command}`
    
    raise message unless $? == 0
    
    message
  end    
  
  # the block is an "executing block"
  def execute
    yield if @executing
  end
  
  # the block is a "checking" block
  def check(message)
    if !@executing
      if yield
        log.info :good, "[*] #{message}"
      else
        fail!("CHECK FAILED: #{message}") unless yield    
      end
    end
  end
  
  def fail!(message = "random failure")
    raise message
  end
  
  def task(message, options = {})
    before_action = options.delete(:before)
    after_action = options.delete(:after)
    
    log.info message do
      begin
        begin
          log.debug "PRE"
          @executing = false
          yield
          
          log.info :good, "PASS"
          return true     # didn't fail, so success! (and nothing needs doing)
        rescue
          log.info :maybe, $!
          # nothing
        end
        
        log.info :maybe, "RUN"
        @executing = true
        shell_or_die before_action if before_action
        yield
        shell_or_die after_action if after_action
        
        log.debug "POST"
        @executing = false
        yield
        
        log.info :good, "DONE"
                
        true
      rescue
        log.error :bad, $!
        
        fail!($!)
      end
    end
  end
  
end