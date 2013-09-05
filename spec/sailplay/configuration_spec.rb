require 'spec_helper'

describe Sailplay::Configuration do
  context 'default' do
    it 'should set the host to sailplay.ru' do
      subject.host.should eq('sailplay.ru')
    end

    it 'should set the protocol to https' do
      subject.protocol.should eq('https')
    end

    it 'should set the port to 443' do
      subject.port.should eq(443)
    end

    it 'should be secure' do
      subject.secure.should be_true
    end

    it 'should set the endpoint to /api' do
      subject.endpoint.should eq('/api')
    end

    it 'shouldn\'t set store_id' do
      subject.store_id.should be_nil
    end

    it 'shouldn\'t set store_key' do
      subject.store_key.should be_nil
    end

    it 'shouldn\'t set store_pin' do
      subject.store_pin.should be_nil
    end

    it 'should set content type to application/json' do
      subject.connection_options[:headers][:accept].should eq('application/json')
    end

    it 'should set correct user agent' do
      subject.connection_options[:headers][:user_agent].should eq("Sailplay Ruby Gem (#{Sailplay::VERSION})")
    end
  end

  describe 'default port' do
    it 'should be 80 when not secure' do
      subject.secure = false
      subject.port.should eq(80)
    end

    it 'should be 443 when secure' do
      subject.secure = true
      subject.port.should eq(443)
    end

    it 'should allow user configuration' do
      subject.port = 1234
      subject.port.should eq(1234)
    end
  end

  describe 'default protocol' do
    it 'should be http when not secure' do
      subject.secure = false
      subject.protocol.should eq('http')
    end

    it 'should be https when secure' do
      subject.secure = true
      subject.protocol.should eq('https')
    end
  end

  describe 'default logger' do
    it 'should have info level' do
      subject.logger.level.should eq(Logger::INFO)
    end
  end
end
