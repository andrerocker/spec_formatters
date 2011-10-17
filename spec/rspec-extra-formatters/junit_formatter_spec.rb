# -*- encoding : utf-8 -*-
# 
# Copyright (c) 2011, Diego Souza
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#   * Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#   * Neither the name of the <ORGANIZATION> nor the names of its contributors
#     may be used to endorse or promote products derived from this software
#     without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require "spec_helper"
require "stringio"
require "builder"
require "rexml/document"

describe JUnitFormatter do
  before(:each) do
    @now = Time.now
    Time.stub(:now).and_return(@now)
  end

  it "should initialize the tests with failures and success" do
    JUnitFormatter.new(StringIO.new).test_results.should eql({:failures=>[], :successes=>[]})
  end

  describe "example_passed" do
    it "should push the example obj into success list" do
      f = JUnitFormatter.new(StringIO.new)
      f.example_passed("foobar")
      f.test_results[:successes].should eql(["foobar"])
    end
  end

  describe "example_failed" do
    it "should push the example obj into failures list" do
      f = JUnitFormatter.new(StringIO.new)
      f.example_failed("foobar")
      f.test_results[:failures].should eql(["foobar"])
    end
  end

  describe "example_pending" do
    it "should do the same as example_failed" do
      f = JUnitFormatter.new(StringIO.new)
      f.example_pending("foobar")
      f.test_results[:failures].should eql(["foobar"])
    end
  end

  describe "read_failure" do
    it "should ignore if there is no exception" do
      example = mock("example")
      example.should_receive(:metadata).exactly(2).times.and_return({:execution_result => { :exception_encountered => nil \
                                                                                          , :exception => nil \
                                                                                          }})
      f = JUnitFormatter.new(StringIO.new)
      f.read_failure(example).should eql("")
    end

    it "should attempt to read exception if exception encountered is nil" do
      strace = mock("stacktrace")
      strace.should_receive(:message).and_return("foobar")
      strace.should_receive(:backtrace).and_return(["foo","bar"])

      example = mock("example")
      example.should_receive(:metadata).exactly(3).times.and_return({:execution_result => { :exception_encountered => nil \
                                                                                          , :exception => strace \
                                                                                          }})

      f = JUnitFormatter.new(StringIO.new)
      f.read_failure(example).should eql("foobar\nfoo\nbar")
    end

    it "should read message and backtrace from the example" do
      strace = mock("stacktrace")
      strace.should_receive(:message).and_return("foobar")
      strace.should_receive(:backtrace).and_return(["foo","bar"])

      example    = mock("example")
      example.should_receive(:metadata).exactly(2).times.and_return({:execution_result => {:exception_encountered => strace}})

      f = JUnitFormatter.new(StringIO.new)
      f.read_failure(example).should eql("foobar\nfoo\nbar")
    end
  end

  describe "dump_summary" do
    it "should print the junit xml" do
      strace = mock("stacktrace")
      strace.should_receive(:message).and_return("foobar")
      strace.should_receive(:backtrace).and_return(["foo","bar"])

      success = { :full_description => "foobar-success",
                  :file_path        => "lib/foobar-s.rb",
                  :execution_result => { :run_time => 0.1 } }

      success_example = mock "success output example"
      success_example.should_receive(:metadata).and_return(success)

      failure = { :full_description => "foobar-failure",
                  :file_path        => "lib/foobar-f.rb",
                  :execution_result => { :exception_encountered => strace,
                  :run_time         => 0.2 } }

      failure_example = mock "failure output example"
      failure_example.should_receive(:metadata).exactly(3).times.and_return(failure)

      output = StringIO.new
      f = JUnitFormatter.new(output)
      f.example_passed(success_example)
      f.example_failed(failure_example)
      f.dump_summary("0.1", 2, 1, 0)

      doc = REXML::Document.new(output.string)
      doc.elements.each("testsuite") do |element|
        element.attributes["errors"].should eql "0"
        element.attributes["failures"].should eql "1"
        element.attributes["tests"].should eql "2"
        element.attributes["time"].should eql "0.1"
        element.attributes["timestamp"].should eql @now.iso8601
      end

      success_testcase = doc.root.detect {|node| node.attributes["name"] == "foobar-success"}
      success_testcase.attributes["classname"].should eql "lib/foobar-s.rb"
      success_testcase.attributes["time"].should eql "0.1"

      failure_testcase = doc.root.detect {|node| node.attributes["name"] == "foobar-failure"}
      failure_testcase.attributes["classname"].should eql "lib/foobar-f.rb"
      failure_testcase.attributes["time"].should eql "0.2"

      failure_testcase.elements.each("failure") do |failure|
        failure.attributes["message"].should eql "failure"
        failure.attributes["type"].should eql "failure"
        failure.text.should eql "foobar\nfoo\nbar"
      end
    end

    it "should escape characteres <,>,&,\" before building xml" do
      example0 = mock("example-0")
      example0.should_receive(:metadata).and_return({ :full_description => "foobar-success >>> &\"& <<<" \
                                                    , :file_path        => "lib/>foobar-s.rb" \
                                                    , :execution_result => { :run_time => 0.1 } \
                                                    })

      output = StringIO.new
      f = JUnitFormatter.new(output)
      f.example_passed(example0)
      f.dump_summary("0.1", 2, 1, 0)

      doc = REXML::Document.new(output.string)
      doc.elements.each("testsuite") do |element|
        element.attributes["errors"].should eql "0"
        element.attributes["failures"].should eql "1"
        element.attributes["tests"].should eql "2"
        element.attributes["time"].should eql "0.1"
        element.attributes["timestamp"].should eql @now.iso8601
      end

      doc.elements.each("testsuite/testcase") do |testcase|
        testcase.attributes["name"].should eql "foobar-success >>> &\"& <<<"
        testcase.attributes["classname"].should eql "lib/>foobar-s.rb"
        testcase.attributes["time"].should eql "0.1"
      end
    end
  end
end
