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

class MiscManager < Toolbase
  
  def run(options = {})
    options.each do |checker, doer|
      task doer do
        check checker do
          shell checker do |resultcode, output|
            log.info resultcode == 0 ? :good : :bad, output
            resultcode == 0
          end
        end
        
        execute do
          log.info shell_or_die(doer)
        end
      end
    end
  end

  def install_passenger_for_apache2
    run 'locate mod_passenger.so' => 'passenger-install-apache2-module -a && updatedb'
  end
  
  
  SOURCE_ROOT = '/usr/local/src/'
  RUBYGEMS_URL_PREFIX = "http://rubyforge.org/frs/download.php/60718/"
  
  def install_rubygems_from_source(version = '1.3.5')
    task "install rubygems from source" do
      check "version of rubygems == #{version}" do
        shell 'gem --version' do |resultcode, output|
          resultcode == 0 && output.strip == version
        end
      end
      
      execute do
        FileUtils.mkdir_p(SOURCE_ROOT)
        
        filename = "rubygems-#{version}.tgz"

        # fetch with wget from rubyforge
        log.info "fetching #{RUBYGEMS_URL_PREFIX}#{filename}"
        shell_or_die "cd #{SOURCE_ROOT} && wget #{RUBYGEMS_URL_PREFIX}#{filename}"

        # extract
        log.info "extracting"
        shell_or_die "cd #{SOURCE_ROOT} && tar xfz #{filename}"

        # run setup.rb
        log.info "running setup.rb"
        shell_or_die "cd #{SOURCE_ROOT}rubygems-#{version} && ruby setup.rb"
        
        log.info "symlinking /usr/bin/gem -> /usr/bin/gem1.8"
        shell_or_die "ln -s /usr/bin/gem1.8 /usr/bin/gem"
      end
    end
  end

end
