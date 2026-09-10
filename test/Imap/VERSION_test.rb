# test/Imap/VERSION_test.rb

require_relative '../test_helper'

describe Imap do
  describe "VERSION" do
    it "is a string" do
      _(Imap::VERSION).must_be_instance_of String
    end

    it "is three numbers separated by dots" do
      _(Imap::VERSION).must_match(/\A\d+\.\d+\.\d+\z/)
    end
  end
end
