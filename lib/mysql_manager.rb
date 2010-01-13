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

class MysqlManager < Toolbase
  
  def start
    task "start mysql" do
      check "mysql is running" do
        shell "/etc/init.d/mysql status" do |result, output|
          result == 0
        end
      end
      
      execute do
        shell_or_die "/etc/init.d/mysql start"
      end
    end
  end
  
  def stop
    task "start mysql" do
      check "mysql is not running" do
        shell "/etc/init.d/mysql status" do |result, output|
          result == 3 && output =~ /stopped/
        end
      end
      
      execute do
        shell_or_die "/etc/init.d/mysql stop"
      end
    end
  end

  def admin_password(password = password_db('mysql/user/root'), old_password = nil)
    task "set mysql password for root@localhost" do
      check "password is correct" do
        shell "mysqladmin --password=#{password} ping 2> /dev/null" do |resultcode, output|
          output != ''
        end
      end
      
      execute do
        shell_or_die "mysqladmin #{"--password=#{old_password}" if old_password} password #{password}"
      end
      
    end
  end
  
  def database(name)
    task "create mysql database #{name}" do
      check "database #{name} exists" do
        connection.query("SHOW DATABASES").first_column.any?(name)
      end
      
      execute do
        connection.execute_unprepared "CREATE DATABASE #{name} DEFAULT CHARACTER SET utf8"
      end
    end
  end
  
  def datadir(location)
    task "move mysql datadir to #{location}" do
      config = File.read('/etc/mysql/my.cnf')
      current_location = config[/^\s*datadir\s*=.*$/].split('=').last.strip
      
      check "datadir is #{location}" do
        current_location == location
      end
      
      check "datadir exists at #{location}" do
        File.directory?(location)
      end
      
      execute do
        shell_or_die '/etc/init.d/mysql stop'
        shell_or_die 'killall mysqld_safe'
        shell_or_die 'killall --signal KILL mysqld_safe'
        
        FileUtils.mv current_location, location unless File.directory?(location)    # might have already moved
        
        # change mysql config file
        File.open '/etc/mysql/my.cnf', 'w' do |f|
          f.write config.gsub(/^\s*datadir\s*=.*$/, "datadir=#{location}")
        end
        
        # change apparmour
        apparmour = File.read('/etc/apparmor.d/usr.sbin.mysqld')
        File.open '/etc/apparmor.d/usr.sbin.mysqld', 'w' do |f|
          f.write apparmour.gsub(/^\s*#{current_location}/, location)
        end
           
        shell_or_die '/etc/init.d/apparmor restart'               
        shell_or_die '/etc/init.d/mysql start'
      end
    end
  end
  
  def cleanup_users
    task "cleanup default users" do
      check "no blank users" do
        !connection.query('SELECT user FROM mysql.user').first_column.any?('')
      end
      
      execute do
        connection.query('SELECT host, user FROM mysql.user').each do |row|
          connection.execute_unprepared "DROP USER #{row['user'].inspect}@#{row['host'].inspect}" unless row['user'] == 'debian-sys-maint' || (row['user'] == 'root' && row['host'] == 'localhost')
        end
      end      
    end
  end
  
  def user(name, host = '%')
    mysql_user = quote_mysql_user(name, host)
    password = password_db("mysql/user/#{name}")
    
    task "create mysql user #{mysql_user}" do
      check "user #{mysql_user} exists" do
        connection.any?('SELECT * FROM mysql.user WHERE user = ? AND host = ?', name, host)
      end
      
      check "user #{mysql_user} has right password" do
        connection.any?('SELECT * FROM mysql.user WHERE user = ? AND host = ? AND password = PASSWORD(?)', name, host, password)
      end
      
      execute do
        connection.execute_unprepared "CREATE USER #{mysql_user} IDENTIFIED BY '#{Mysql.quote(password)}'" unless connection.any?('SELECT * FROM mysql.user WHERE user = ? AND host = ?', name, host)
        connection.execute "UPDATE mysql.user SET password = PASSWORD(?) WHERE user = ? AND HOST = ?", password, name, host          
      end
    end
  end
  
  def grant(name, host, database, privs)
    mysql_user = quote_mysql_user(name, host)

    task "grant #{privs.join(', ')} to #{mysql_user} on #{database}" do
      check "#{mysql_user} has #{privs.join(', ')} on #{database}" do
        if database == '*'
          query = connection.query('SELECT * FROM mysql.user WHERE user = ? AND host = ?', name, host)
        else
          query = connection.query('SELECT * FROM mysql.db WHERE user = ? AND host = ? AND db = ?', name, host, database)
        end
        
        query.any? do |row|
          privs.all? { |priv| row["#{priv}_priv"] == 'Y' }
        end
      end
      
      execute do
        connection.execute_unprepared "GRANT #{privs.join(', ')} ON #{database}.* TO #{mysql_user}"
      end
    end
  end
  
  def grant_tables(name, host, database, tables, privs)
    mysql_user = quote_mysql_user(name, host)

    tables.each do |table|
      task "grant #{privs.join(', ')} to #{mysql_user} on #{database}.#{table}" do
        check "#{mysql_user} has #{privs.join(', ')} on #{database}.#{table}" do
          privs.all? do |priv|
            connection.query('SELECT * FROM mysql.tables_priv WHERE user = ? AND host = ? AND db = ? AND table_name = ? AND FIND_IN_SET(?, table_priv)', name, host, database, table, priv).any?
          end
        end
        
        execute do
          connection.execute_unprepared "GRANT #{privs.join(', ')} ON #{database}.#{table} TO #{mysql_user}"
        end
      end
    end
  end

  private
  
  def quote_mysql_user(name, host)
    "'#{Mysql.quote(name)}'@'#{Mysql.quote(host)}'"
  end
  
  public
  
  def connection(host = 'localhost', user = 'root')
    @connection ||= MysqlConnection.new(host, user, password_db("mysql/user/#{user}"), nil)
  end
  
end