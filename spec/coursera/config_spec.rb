require 'spec_helper'
require 'coursera/config'

describe Coursera::Config do
  before :each do
    Coursera::Config.any_instance.stub(:load_file!).and_return({})
    Coursera::Config.any_instance.stub(:check_required_attributes!)
  end

  it "#halt should be set to false if halt is false" do
    conf_yml = %Q{
      foo:
        halt: false
    }
    Coursera::Config.any_instance.unstub(:load_file!)
    File.stub(:open).and_return(conf_yml)
    config = Coursera::Config.load_from_file
    config.halt.should == false
  end

  it "should have correct default values" do
    config = Coursera::Config.load_from_file
    config.halt.should == true
    config.sleep_duration.should == 300
    config.num_threads.should == 1
  end

  describe "#load_file!" do
    before :each do
      Coursera::Config.any_instance.stub(:update!)
      Coursera::Config.any_instance.unstub(:load_file!)
    end
    let (:config) { Coursera::Config.load_from_file }

    it "when configuration name is specified loads specified config hash" do
      conf_yml = %Q{
          default: foo
          bar: good
          foo: bad
      }
      File.stub(:open).and_return(conf_yml)
      config.send(:load_file!, 'file_name', 'bar').should == "good"
    end

    context "when configuration name is not specified" do
      it "when default exists should load the config hash specified by default" do
        conf_yml = %Q{
          default: foo
          bar: bad
          foo: good
        }
        File.stub(:open).and_return(conf_yml)
        config.send(:load_file!, 'file_name').should == "good"
      end

      it "when default missing should load the first config hash" do
        conf_yml = %Q{
          bar: good
          foo: bad
        }
        File.stub(:open).and_return(conf_yml)
        config.send(:load_file!, 'file_name').should == "good"
      end
    end
  end

  describe "#check_required_attributes!" do
    let(:attrs){ {:endpoint_uri => nil, :api_key => nil, :autograders_yml => nil} }
    let(:config) { Coursera::Config.load_from_file }
    before :each do
      Coursera::Config.any_instance.stub(:load_file!).and_return(attrs)
      Coursera::Config.any_instance.unstub(:check_required_attributes!)
    end

    it "should require endpoint_uri" do
      attrs.delete :endpoint_uri
      lambda{config}.should raise_error(ArgumentError)
    end
    it "should require api_key" do
      attrs.delete :api_key
      lambda{config}.should raise_error(ArgumentError)
    end
    it "should require autograders_yml" do
      attrs.delete :autograders_yml
      lambda{config}.should raise_error(ArgumentError)
    end

    it "should work when all required attributes are specified" do
      lambda{config}.should_not raise_error
    end
  end

  describe "operations" do
    let(:config) {Coursera::Config.new}
    it "can set values" do
      config.foo = "bar"
      config.foo.should == "bar"
    end

    it "can set nested hashes" do
      config.foo = {:bar => "baz"}
      config.foo.bar.should == "baz"
    end
  end
end
