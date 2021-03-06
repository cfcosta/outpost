require 'test_helper'

describe Outpost::Scout do
  NoisyError = Class.new(StandardError)

  class ScoutExample < Outpost::Scout
    attr_accessor :response
    expect :response, lambda {|scout, status| scout.response == status }

    def setup(*args); end
    def execute(*args); end
  end

  it "should report up when status match" do
    scout = ScoutExample.new("a scout", config_mock)
    scout.response = true
    assert_equal :up, scout.run
  end

  it "should report up when status match" do
    scout = ScoutExample.new("a scout", config_mock)
    scout.response = false
    assert_equal :down, scout.run
  end

  it "should not register an invalid expectation" do
    assert_raises ArgumentError do
      add_expectation(:invalid_expectation, nil)
    end
  end

  it "should register a expectation using a lambda" do
    add_expectation(:valid_expectation, lambda{|b| b})

    refute_nil ScoutExample.expectations[:valid_expectation]
  end

  it "should register a expectation using pure blocks for flexibility" do
    ScoutExample.expect(:valid_expectation) { |b| b }

    refute_nil ScoutExample.expectations[:valid_expectation]
  end

  it "should not be able to have its expectations modified" do
    ScoutExample.expectations[:another_expectation] = {}
    assert_nil ScoutExample.expectations[:another_expectation]
  end

  it "should not call expectation when there are no rules for that" do
    add_expectation(:noisy, proc {|s,r| raise NoisyError})
    assert_nothing_raised do
      scout = ScoutExample.new("a scout", config_mock)
      scout.run
    end
  end

  it "should call expectation when there are rules for that" do
    add_expectation(:noisy, proc {|s,r| raise NoisyError})
    config = config_mock
    config.reports[{:noisy => nil}] = :down

    assert_raises NoisyError do
      scout = ScoutExample.new("a scout", config)
      scout.run
    end
  end

  it "should complain when an unregistered expectation is called" do
    config = config_mock
    config.reports[{:unregistered => nil}] = :up

    assert_raises NotImplementedError do
      scout = ScoutExample.new("a scout", config)
      scout.run
    end
  end

  private
  def config_mock
    reports = {
      {:response => true}  => :up,
      {:response => false} => :down
    }
    build_stub(:reports => reports)
  end

  def add_expectation(expectation, callable)
    ScoutExample.expect expectation, callable
  end
end
