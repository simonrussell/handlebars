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

class MysqlQuery
  
  def initialize(connection, query_string, *params)
    @connection = connection
    @query_string = query_string
    @params = params
  end
  
  def each
    run { |row| yield row }
  end
  
  def any?
    return count > 0 unless block_given?
    
    run do |row|
      return true if yield(row)
    end
    
    false
  end
  
  def count
    run_count
  end
  
  def count_affected
    run_count_affected
  end
  
  def first_column
    MysqlColumn.new(self)
  end
    
  private
  
  def run_wrapped
    statement = @connection.real_connection.prepare(@query_string)
    statement.execute(*@params)
    yield statement
    
  ensure
    statement.close if defined?(statement) && statement    
  end
  
  def run_count
    run_wrapped { |statement| statement.num_rows }
  end
  
  def run_count_affected
    run_wrapped { |statement| statement.affected_rows }
  end
  
  def run
    run_wrapped do |statement|
      if block_given?
        columns = statement.result_metadata.fetch_fields.map { |f| f.name }
    
        statement.each do |row_array|
          row = {}
          
          row_array.each_with_index do |field, index|
            row[columns[index].downcase] = field
          end
              
          yield row
        end
      end
      
      self      
    end
    
  ensure
    statement.close if defined?(statement) && statement
  end
    
end