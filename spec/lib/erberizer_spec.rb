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

require "#{File.dirname(__FILE__)}/../spec_helper"

describe Erberizer do

  describe "initialization" do
    
    it "should initialize with no fields" do
      Erberizer.new
    end
    
    it "should initialize with some fields" do
      Erberizer.new(:fish => :biscuits, :bob => :fred)
    end

    it "should should set instance variables" do
      e = Erberizer.new(:fish => :biscuits, :bob => :fred)
      
      e.instance_variable_get('@fish').should == :biscuits
      e.instance_variable_get('@bob').should == :fred
    end
    
  end
  
  describe "#file" do
    
    before do
      erb_compiled = '[@fish, @biscuits]'
      File.stub!(:read => erb_compiled)
      
      @erb_mock = mock
      @erb_mock.stub!(:src => erb_compiled)
      
      ERB.stub!(:new => @erb_mock)
    end
    
    it "should read the file" do
      File.should_receive(:read).with('test').and_return('')
      
      Erberizer.file('test')
    end
    
    it "should construct an ERB based on what's read" do
      ERB.should_receive(:new).with(File.read).and_return(@erb_mock)
      
      Erberizer.file('test')
    end
    
    it "should pass the fields to the erberizer" do
      Erberizer.should_receive(:new).with(:fish => :biscuits, :bob => :fred)
      
      Erberizer.file('test', :fish => :biscuits, :bob => :fred)
    end

  end

end