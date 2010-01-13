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

class ServerContext
  include DataTools
  
  attr_reader :hostname
  
  def initialize(hostname)
    @hostname = hostname
    @recipes = {}
    @tasks = {}
    @included_recipes = []
  end
  
  def ohai(*args)
    @ohai ||= OhaiManager.from_command(self)
    
    if args.empty?
      @ohai
    else
      @ohai.default(*args)
    end
  end
  
  def template(name, fields = {})
    Erberizer.file(app_base_filename('templates', name), fields)
  end
  
  def recipe(name, &block)
    @recipes[name] = block
  end

  def cook(*recipe_names)
    recipe_names.flatten.each do |recipe_name|
      recipe_name = recipe_name.to_s
      
      raise "unknown recipe #{recipe_name}" unless @recipes.key?(recipe_name)
            
      unless @included_recipes.include?(recipe_name)
        @included_recipes << recipe_name

        log.info "recipe: #{recipe_name}" do
          @recipes[recipe_name].call
        end        
      end
    end
  end
  
  def finish_cooking
    @iptables.finish_cooking if @iptables
  end
  
  {
    :package => :PackageManager,
    :gem => :GemManager,
    :file => :FileManager,
    :config => :ConfigManager,
    :misc => :MiscManager,
    :git => :GitManager,
    :directory => :DirectoryManager,
    :auth => :AuthManager,
    :mysql => :MysqlManager,
    :cron => :CronManager,
    :iptables => :IptablesManager
  }.each do |name, klass|
    eval "def #{name}(*args)\n@#{name} ||= #{klass}.new(self)\n@#{name}.default(*args) unless args.empty?\n@#{name}\nend"
  end
  
  def log
    @log ||= NiceLogger.new
  end
  
  def group(name)
    log.info name do
      yield
    end
  end
  
  def self.setup(hostname, &block)
    c = ServerContext.new(hostname)
    c.send(:preload_recipes_and_tasks)
    c.instance_eval(&block)
    c
  end
  
  def perform(name, *args)
    raise "unknown task #{name}" unless @tasks.key?(name)
    
    code = @tasks[name]
    raise "#{name} needs #{code.arity} arguments, #{args.length} supplied" unless args.length == code.arity
    
    code.call(*args)
  end
  
  def task(name, &block)
    @tasks[name] = block
  end
  
  PASSWORD_PROMPT_REGEX = /\[\*\* password ([^\s]+) \*\*\]/

  def password_db(name)
    passwords = read_data_kv('password-db')
    
    if passwords.key?(name)
      passwords[name]
    else
      STDOUT.flush
      STDOUT.write "[** password #{name} **]"
      STDOUT.flush
      result = STDIN.gets.strip
      
      append_data_kv('password-db', name, result)
      
      result
    end
  end

  def ip_by_role(role)
    all_ips_by_role(role).first
  end
  
  def all_ips_by_role(role)
    servers = ServerList.read.by_role(role)
    servers.values.map { |v| v['server'] }
  end

  private

  def preload_recipes_and_tasks
    # load shared stuff
    preload 'handlebars/tasks', 'task'
    preload 'handlebars/recipes', 'recipe'
    
    # load site specific stuff
    preload 'tasks', 'task'
    preload 'recipes', 'recipe'
  end

  def preload(dirname, method)
    prefix = File.join($APP_BASE, "#{dirname}/")
    
    Dir.glob("#{prefix}**/*.rb").each do |filename|
      recipe_code = File.read(filename)
      stumpy_filename = filename[prefix.length .. -4]
      instance_eval "#{method} #{stumpy_filename.inspect} do\n#{recipe_code}\nend", "#{dirname}/#{stumpy_filename}", 0
    end
  end
  
end