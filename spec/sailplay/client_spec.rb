require 'spec_helper'

describe Sailplay::Client do

  describe 'configuration' do
    it 'should set the defaults' do
      Sailplay.reset!
      Sailplay.client.host.should eq('sailplay.ru')
      Sailplay.client.port.should eq(443)
      Sailplay.client.secure.should be_true
      Sailplay.client.endpoint.should eq('/api/v1')
    end

    it 'should set the options' do
      Sailplay.configure do |c|
        c.host = 'test.me'
        c.endpoint = 'megaapi'
        c.store_id = 'test_id'
        c.store_key = 'test_key'
        c.store_pin = 'test_pin'
      end


      Sailplay.client.host.should eq('test.me')
      Sailplay.client.endpoint.should eq('megaapi')
      Sailplay.client.store_id.should eq('test_id')
      Sailplay.client.store_key.should eq('test_key')
      Sailplay.client.store_pin.should eq('test_pin')
    end
  end

  describe '.request' do
    let(:config) do
      Sailplay::Configuration.new.tap do |c|
        c.store_id = 'id'
        c.store_key = 'key'
        c.store_pin = '1111'
      end
    end

    context 'with invalid client configuration' do
      it 'should raise if store_id is not configured' do
        config.store_id = nil
        client = Sailplay::Client.new(config)
        lambda { client.request(:get, 'call') }.should raise_error(Sailplay::ConfigurationError)
      end

      it 'should raise if store_key is not configured' do
        config.store_key = nil
        client = Sailplay::Client.new(config)
        lambda { client.request(:get, 'call') }.should raise_error(Sailplay::ConfigurationError)
      end

      it 'should raise if store_pin is not configured' do
        config.store_pin = nil
        client = Sailplay::Client.new(config)
        lambda { client.request(:get, 'call') }.should raise_error(Sailplay::ConfigurationError)
      end
    end

    context 'when authentication is required' do
      before do
        @client = Sailplay::Client.new(config)
        stub_http_request(:get, %r{/action\d?}).to_return(:body => '{"status":"ok"}')
      end

      let(:login_url) {
        stub_http_request(:get, 'https://sailplay.ru/api/v1/login').
            with(:query => {:store_department_id => 'id', :store_department_key => 'key', :pin_code => '1111'})
      }

      it 'should request the token' do
        login_url.to_return(:body => '{"status":"ok","token":"some_new_token"}')
        @client.request(:get, 'action')
        login_url.should have_been_requested
      end

      it 'should cache the recieved token' do
        login_url.to_return(:body => '{"status":"ok","token":"some_new_token"}')
        @client.request(:get, 'action')
        @client.request(:get, 'action1')
        login_url.should have_been_requested.once
      end
    end


    context 'error handling' do
      let(:login) do
        stub_http_request(:any, %r{https://sailplay.ru/api/v1/login})
      end

      before do
        @client = Sailplay::Client.new(config)
      end

      it 'should raise when cannot connect to server' do
        login.to_raise(SocketError)

        lambda { @client.request(:get, 'call') }.should raise_error(Sailplay::APIConnectionError) do |e|
          e.message.should match("Unexpected error communicating when trying to connect to Sailplay.  HINT: You may be seeing this message because your DNS is not working.  To check, try running 'host sailplay.ru' from the command line.")
        end
      end

      it 'should raise when cannot connect to server due timeout' do
        login.to_timeout

        lambda { @client.request(:get, 'call') }.should raise_error(Sailplay::APIConnectionError) do |e|
          e.message.should match("Unexpected error communicating when trying to connect to Sailplay.  HINT: You may be seeing this message because your DNS is not working.  To check, try running 'host sailplay.ru' from the command line.")
        end
      end

      it 'should raise when response is not a valid JSON' do
        login.to_return(:body => '{123')

        lambda { @client.request(:get, 'call') }.should raise_error(Sailplay::APIError) do |e|
          e.http_status.should eq(200)
          e.http_body.should eq('{123')
          e.message.should match('Invalid response object from API')
        end
      end
    end
  end
end