ENV['RACK_ENV'] = 'test'

require_relative '../bin/fortune'

require 'open3'
require 'rack/test'

describe 'fortune' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def status(i)
    status = double(Process::Status)
    status.stub(:exitstatus).and_return(i)
    status
  end

  def assert_success(url, expected_command)
    Open3.should_receive(:capture3).with(expected_command).and_return(
      ['fortune text', '', status(0)])

    get(url)

    last_response.content_type.should match(/json/)
    last_response.status.should eq(200)
    last_response.body.should eq('{"text":"fortune text"}')
  end

  it 'translates URL parameters to command-line flags' do
    assert_success('/fortune/', 'fortune -a')
    assert_success('/fortune/?long=0', 'fortune -s -a')
    assert_success('/fortune/?long=1', 'fortune -l -a')
    assert_success('/fortune/?dirty=0', 'fortune')
    assert_success('/fortune/?dirty=1', 'fortune -o')
    assert_success('/fortune/?dirty=0&long=0', 'fortune -s')
    assert_success('/fortune/?dirty=0&long=1', 'fortune -l')
    assert_success('/fortune/?dirty=1&long=0', 'fortune -s -o')
    assert_success('/fortune/?dirty=1&long=1', 'fortune -l -o')
  end

  it 'successfully gets a random fortune from the command line' do
    get('/fortune/')

    last_response.content_type.should match(/json/)
    last_response.status.should eq(200)
    last_response.body.should match(/\{"text":".+"\}/)
  end

  it 'throws an error when the fortune command fails' do
    Fortune.stub(:command).and_return('fortune -bogus')

    proc { get('/fortune/') }.should raise_error(Fortune::CommandFailed)
  end

  it 'throws an error when the fortune command does not exist' do
    Fortune.stub(:command).and_return('no-such-command')

    proc { get('/fortune/') }.should raise_error(SystemCallError)    
  end
end
