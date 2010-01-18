require File.join(File.dirname(__FILE__), '../lib/init')

FileUtils.ln_s 'handlebars/handlebars.rb', File.join($APP_BASE, 'hb')
FileUtils.mkdir %w(data files recipes tasks templates).map { |d| File.join($APP_BASE, d) }.reject { |d| File.exist?(d) }

unless File.exist?(File.join($APP_BASE, 'servers.yml'))
  File.open File.join($APP_BASE, 'servers.yml'), 'w' do |f|
    f.puts "# central database for your servers
# example:
# myserver:
#   server: 1.2.3.4
#   mirror: http://your.ubuntu.mirror
#   roles:
#     - role1
#     - role2
"
  end
end
