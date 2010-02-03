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

class MysqlConnection
  
  attr_reader :real_connection
  
  def initialize(host, user, password, database)
    require 'mysql'   # just in case it's not loaded
    @real_connection = Mysql.new(host, user, password, database)
    @real_connection.reconnect = true
  end
  
  def query(*args)
    MysqlQuery.new(self, *args)
  end
  
  def any?(*args)
    count(*args) > 0
  end

  def count(*args)
    query(*args).count
  end
  
  def execute(*args)
    query(*args).count_affected
    
    true    
  end
  
  def execute_unprepared(sql)
    @real_connection.query(sql) do |result|
      # not much, how do we check success?
    end
  end
  
end
