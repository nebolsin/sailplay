require 'forwardable'
require 'logger'

require 'sailplay/version'

require 'sailplay/client'
require 'sailplay/error'
require 'sailplay/configuration'
require 'sailplay/response'

require 'sailplay/api/base'
require 'sailplay/api/user'
require 'sailplay/api/gift'
require 'sailplay/api/purchase'

module Sailplay
  class << self
    # The client object is responsible for communication with Sailplay API server.
    attr_writer :client

    # A Sailplay configuration object.
    attr_writer :configuration

    # Call this method to modify defaults in your initializers.
    #
    # @example
    #   Sailplay.configure do |config|
    #     config.store_id = '123'
    #     config.store_key = '4567890'
    #     config.store_pin = '3131'
    #     config.secure  = true
    #   end
    def configure
      yield(configuration)
      @client = Client.new(configuration)
    end

    # The configuration object.
    # @see Sailplay.configure
    def configuration
      @configuration ||= Configuration.new
    end

    def client
      @client ||= Client.new(configuration)
    end

    def reset!
      @client = nil
      @configuration = nil
    end

    def logger
      self.configuration.logger
    end

    def request(method, url, params)
      client.request(method, url, params)
    end
  end
end