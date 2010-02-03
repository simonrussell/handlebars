if ARGV.length < 1
  STDERR.puts "usage: #{$0} password <name-of-password>"
  exit(1)
end

include DataTools
passwords = DataTools.read_data_kv('password-db')

STDOUT.write passwords[ARGV[0]]
