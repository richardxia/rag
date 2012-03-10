require 'spec_helper'
require 'coursera_client'

class URIMatcher
  def initialize(uri)
    @uri = uri
  end
  def ==(uri)
    uri.to_s == @uri
  end
  def description
    "A URI matching '#{@uri}'"
  end
end
def uri_matching(text)
  URIMatcher.new(text)
end

describe CourseraClient do
  around :each do |example|
    # This is a weird workaround because RSpec is catching an exception it
    # shouldn't be catching
    # timeout without a second argument internally raises an error, catches
    # it, and returns a Timeout:Error
    # RSpec is somehow catching that internal error
    Timeout::timeout(1, Timeout::Error) do
      example.run
    end
  end

  before :each do
    CourseraClient.any_instance.should_not_receive(:decode_submission)
    CourseraController.stub(:new).and_return(controller)
  end
  let(:controller) { double('fake controller').as_null_object }
  let(:client) { CourseraClient.new }

  context 'when initialized' do
    it "@autograders should be a mapping from assignment_part_sid's to URIs and grader types" do
      autograders_yml = <<EOF
test-assign-1-part-1:
  uri: http://test.url/
  type: WeightedRspecGrader
EOF
      File.should_receive(:open).with('autograders.yml', 'r').and_return(autograders_yml)

      #CourseraClient.any_instance.stub(:load_configurations).and_return('autograders_yml' => 'autograders.yml')
      mock_config = double(:autograders_yml => 'autograders.yml').as_null_object
      Coursera::Config.stub(:new).and_return(mock_config)
      client.instance_eval{@autograders}.should == {
        'test-assign-1-part-1' => { uri: 'http://test.url/', type: 'WeightedRspecGrader'},
      }
    end
  end

  describe "#run" do
    let(:mock_conf) { {'num_threads' => 1} }
    before :each do
      autograder = {'test-assignment' => { :uri => 'http://example.com', :type => 'RspecGrader' } }
      CourseraClient.any_instance.stub(:load_configurations).and_return(mock_conf)
      CourseraClient.any_instance.stub(:init_autograders).and_return(autograder)
    end

    context "with one autograder" do

      it 'should exit if the submission queue is empty' do
        RagLogger.logger.info("begin_spec")
        controller.should_not_receive(:get_pending_submission)
        controller.should_receive(:get_queue_length).and_return(0)
        client.should_not_receive(:decode_submission)
        client.run
      end

      it 'should do nothing' do
        RagLogger.logger.info("begin_next_spec")
      end

      context 'when the submission queue is not empty' do
        before :each do
          controller.stub(:get_queue_length).and_return(1, 0)
          controller.stub(:get_pending_submission).and_return(submission)
          client.stub(:decode_submission).and_return 'submission'
          client.stub(:load_spec)
          client.stub(:run_autograder_subprocess)
          client.stub(:format_for_html)
        end

        let(:submission) { double('fake_submission').as_null_object }

        it 'should fetch a submission' do
          controller.should_receive(:get_pending_submission)
          client.run
        end

        it 'should retry fetching a submission if it does not get a valid submission' do
          controller.stub(:get_queue_length).and_return(1, 1, 0)
          controller.should_receive(:get_pending_submission).twice.and_return(nil, submission)
          client.run
        end

        it 'should run the autograder' do
          client.should_receive(:run_autograder_subprocess)
          client.run
        end

        it 'should submit the score' do
          controller.should_receive(:post_score)
          client.run
        end
      end
    end

    context "with multiple autograders"

    it "should not halt if @halt is false" do
      mock_conf[:halt] = false
      client.stub(:run_and_score)
      lambda{client.run}.should raise_error(Timeout::Error)
    end
  end

  describe "#load_spec" do
    before :each do
      CourseraClient.any_instance.stub(:load_configurations).and_return(double.as_null_object)
      CourseraClient.any_instance.stub(:init_autograders).and_return(autograder)
    end
    let(:assignment_part_sid) { 'test-assignment' }
    let(:spec_uri) { 'http://example.com' }
    let(:autograder) do
      {
        assignment_part_sid => {
          :uri => spec_uri,
        }
      }
    end

    def run_load_spec
      client.send(:load_spec, assignment_part_sid)
    end

    context 'when autograder is cached' do
      let(:cached_path) { 'cache' }
      before :each do
        autograder[assignment_part_sid][:cache] = double('fake_cache_file', :path => cached_path)
      end

      it 'should return the cached autograder' do
        run_load_spec.should be cached_path
      end
      it 'should not send an HTTP request' do
        Net::HTTP.should_not_receive(:get_response)
        run_load_spec
      end
    end

    context 'when autograder is not cached' do
      let(:response) { double('response', :code => '200').as_null_object }
      before :each do
        Net::HTTP.stub(:get_response).and_return(response)
      end

      it 'should return the path to the autograder' do
        spec_file = double('fake file', :path => 'fake_path').as_null_object
        Tempfile.stub(:new).and_return(spec_file)
        run_load_spec.should be spec_file.path
      end

      it 'should send an HTTP request' do
        Net::HTTP.should_receive(:get_response).with(uri_matching(spec_uri)).and_return(response)
        run_load_spec
      end

      it "raises an error when it can't retrieve the remote file" do
        response = double('response', :code => '404').as_null_object
        Net::HTTP.stub(:get_response).and_return(response)
        lambda { run_load_spec }.should raise_error(CourseraClient::SpecNotFound)
      end
    end

    context 'when autograder is a local file' do
      let(:spec_uri) { 'local_path' }
      it 'should return the local file' do
        run_load_spec.should == 'local_path'
      end

      it 'should not send an HTTP request' do
        Net::HTTP.should_not_receive(:get_response)
        run_load_spec
      end
    end

    it 'should raise an error if requested autograder is not found'
  end

  describe "#load_configuration" do
    before :each do
      #CourseraClient.any_instance.stub(:load_configurations).and_return double('fake hash').as_null_object
      CourseraClient.any_instance.stub(:init_autograders)
    end
  end

  describe "#run_autograder_subprocess"
  describe "#parse_grade"
  describe "#decode_submission" # This method probably belongs in the controller
end
