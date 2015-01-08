require 'fileutils'
require 'support/integration_spec_support'

module Pact
  module ControlServerTestSupport
    include IntegrationTestSupport

    def mock_service_headers
      {
        'Content-Type' => 'application/json',
        'X-Pact-Mock-Service' => 'true',
        'X-Pact-Consumer' => 'Consumer',
        'X-Pact-Provider' => 'Provider'
      }
    end
  end
end

describe "The pact-mock-service control server command line interface", mri_only: true do

  include Pact::ControlServerTestSupport

  before :all do
    FileUtils.rm_rf 'tmp'

    @pid = nil
    @pid = fork do
      exec "bundle exec bin/pact-mock-service control --port 1234 --log-dir tmp/log --pact-dir tmp/pacts"
    end

    wait_until_server_started 1234
  end

  it "starts up and responds with mocked responses" do
    response = setup_interaction 1234
    expect(response.status).to eq 200
    mock_service_port = URI(response.headers['X-Pact-Mock-Service-Location']).port

    response = invoke_expected_request mock_service_port
    expect(response.status).to eq 200
    expect(response.body).to eq 'Hello world'

    Process.kill "INT", @pid
    sleep 1
    @pid = nil
    # write_pact 1234
    # expect(response.status).to eq 200
  end

  it "writes logs to the specified log file" do
    expect(Dir.glob('tmp/log/*.log').size).to be 1
  end

  it "writes the pact to the specified directory" do
    expect(File.exist?('tmp/pacts/consumer-provider.json')).to be true
  end

  after :all do
    if @pid
      Process.kill "INT", @pid
    end
  end
end