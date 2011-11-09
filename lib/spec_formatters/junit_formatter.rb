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

require "rubygems"
require "time"
require "builder"
require "spec/runner/formatter/base_formatter"

class JUnitFormatter < Spec::Runner::Formatter::BaseFormatter
  attr_reader :test_results
  attr_reader :output

  def initialize(options, output)
    super(options, output)
    @test_results = { :failures => [], :successes => [], :exceptions => {} }
    @output = output
  end

  def example_passed(example)
    super(example)
    @test_results[:successes].push(example)
  end

  def example_pending(example, count, failure)
    self.example_failed(example, count, failure)
  end

  def example_failed(example, count, failure)
    super(example, count, failure)
    @test_results[:failures].push(example)
    @test_results[:exceptions][example] = failure
  end

  def dump_summary(duration, example_count, failure_count, pending_count)
    super(duration, example_count, failure_count, pending_count)
    node_attributes = { :errors => 0, :failures => failure_count+pending_count,
                        :tests => example_count, :time => duration, :timestamp => Time.now.iso8601 }

    builder = Builder::XmlMarkup.new(:target => output, :ident => 2)
    builder.instruct!
    builder.testsuite node_attributes do |suite|
      suite.properties
      dump_specs suite, @test_results[:successes]
      dump_specs suite, @test_results[:failures] do |testcase, spec|
        testcase.failure :message => "failure", :type => "failure" do |failure|
          failure.cdata! @test_results[:exceptions][spec]
        end
      end
    end
  end

  def dump_specs(propertie, specs)
    specs.each do |spec|
      node_attributes = { :classname => spec.location, :name => spec.description, :time => 0 }

      if block_given?
        propertie.testcase node_attributes do |node|
          yield(node, spec)
        end

        return
      end

      propertie.testcase node_attributes
    end
  end
end
