#!/usr/bin/env ruby

require 'handlebars/lib/init'

if ARGV.length < 1 || ARGV.first !~ /^\w+$/
  STDERR.puts "usage: handlebars <command> [<command-args ...>]"
  STDERR.puts
  STDERR.puts "available commands:"
  
  Dir.glob('handlebars/commands/*.rb').each do |cmd|
    puts File.basename(cmd, '.rb')
  end

  exit 1
end

load "handlebars/commands/#{ARGV.shift}.rb"
