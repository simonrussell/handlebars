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

class CronManager < Toolbase
  
  def schedule(command, options = {})
    user = options[:user] || 'root'
    at = options[:at]
    comment = options[:comment]
    
    cronline = "#{make_cronline(at, "#{@server_context.hostname} #{command}".hash.abs)} #{user} #{command}"
    fail!("invalid cronline #{cronline}") unless valid_cronline?(cronline)
    
    cronline << " ### #{comment}" if comment
    @server_context.file.line '/etc/crontab', cronline
  end
  
  alias :default :schedule
  
  private
  
  def make_cronline(spec, random_seed)
    if spec == :nightly
      srand(random_seed)
      make_cronline({:hour => rand(4), :minute => rand(60)}, random_seed)
    elsif spec == :two_hourly
      srand(random_seed)
      make_cronline({:hour => '*/2', :minute => rand(60)}, random_seed)      
    elsif spec.is_a?(Hash)
      spec = { :minute => '*', :hour => '*', :day_of_month => '*', :month => '*', :day_of_week => '*' }.merge(spec)
      
      "#{spec[:minute]} #{spec[:hour]} #{spec[:day_of_month]} #{spec[:month]} #{spec[:day_of_week]}"
    else
      raise "don't know how to build cronline from #{spec.inspect}"
    end
  end
  
  def valid_cronline?(line)
    line =~ /\A([^ \t\n]+[ \t]+){6}[^ \t\n][^\n]*\Z/
  end
  
end
