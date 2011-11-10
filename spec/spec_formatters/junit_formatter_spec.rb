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
  let(:f) do
    JUnitFormatter.new({}, StringIO.new)
  end

  it "should initialize the tests with failures and success" do
    f.test_results.should eql({:failures=>[], :successes=>[], :exceptions=>{}})
  end

  describe "example_passed" do
    it "should push the example obj into success list" do
      f.example_passed("foobar")
      f.test_results[:successes].should eql(["foobar"])
    end
  end

  describe "example_failed" do
    it "should push the example obj into failures list" do
      f.example_failed("foobar", 0, "a failure")
      f.test_results[:failures].should eql(["foobar"])
    end
  end

  describe "example_pending" do
    it "should do the same as example_failed" do
      f.example_pending("foobar", 0, "a pending")
      f.test_results[:failures].should eql(["foobar"])
    end
  end

  describe "dump_summary" do
    it "should print the junit xml" do
      now = Time.now
      Time.stub(:now).and_return(now)

      success_example = mock "success output example"
      success_example.should_receive(:location).and_return("lib/foobar-s.rb")
      success_example.should_receive(:description).and_return("foobar-success")

      failure_example = mock "failure output example"
      failure_example.should_receive(:location).and_return("lib/foobar-f.rb")
      failure_example.should_receive(:description).and_return("foobar-failure")

      f.example_passed(success_example)

      exception = mock "exception"
      exception.should_receive(:message).and_return("failed")

      failure = mock "failure"
      failure.should_receive(:exception).and_return(exception)

      f.example_failed(failure_example, 0, failure)
      f.dump_summary("0.1", 2, 1, 0)

      doc = REXML::Document.new(f.output.string)
      doc.elements.each("testsuite") do |element|
        element.attributes["errors"].should eql "0"
        element.attributes["failures"].should eql "1"
        element.attributes["tests"].should eql "2"
        element.attributes["time"].should eql "0.1"
        element.attributes["timestamp"].should eql now.iso8601
      end

      success_testcase = doc.root.elements["testcase[@name='foobar-success']"]
      success_testcase.attributes["classname"].should eql "lib/foobar-s.rb"
      success_testcase.attributes["time"].should eql "0"

      failure_testcase = doc.root.elements["testcase[@name='foobar-failure']"]
      failure_testcase.attributes["classname"].should eql "lib/foobar-f.rb"
      failure_testcase.attributes["time"].should eql "0"

      failure = failure_testcase.elements["failure"]
      failure.attributes["message"].should eql "failure"
      failure.attributes["type"].should eql "failure"
      failure.cdatas[0].to_s.should eql "failed"
    end
  end

  describe "error stuff" do
    it "should throw e error" do
      true.should be false 
    end
  end
end
