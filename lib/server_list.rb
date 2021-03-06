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

class ServerList

  def initialize(hostname, servers)
    servers = [servers] unless servers.is_a?(Array)
    @servers = servers.find { |group| group.has_key?(hostname) } || {}
  end

  def [](hostname)
    @servers[hostname]
  end

  def self.cook(hostname, recipes)
    server_spec = read(hostname)[hostname]

    ServerContext.setup(hostname) do
      log.info "server: #{hostname}" do
        if recipes
          cook recipes
        elsif server_spec
          cook (server_spec['roles'] || []).map { |r| "roles/#{r}" }
          finish_cooking
        end
      end
    end
  end

  def by_role(name)
    result = {}

    @servers.each do |hostname, info|
      result[hostname] = info if info['roles'].include?(name)
    end

    result
  end

  def self.read(hostname, filename = File.join($APP_BASE, 'servers.yml'))
    new(hostname, YAML.load_file(filename))
  end

end
