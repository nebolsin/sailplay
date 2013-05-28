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

    # @param [String] phone
    # @param [Hash]   options
    #
    # @option options [true|false] :auth — authenticate user
    #
    # @return [Sailplay::User]
    def create_user(phone, options = {})
      self.client.create_user(phone, options)
    end

    # @param [String] phone
    # @param [Hash]   options
    #
    # @option options [true|false] :auth — authenticate user
    #
    # @return [Sailplay::User]
    def find_user(phone, options = {})
      self.client.find_user(phone, options)
    end

    # @param [String|Integer] phone_or_user_id
    # @param [BigDecimal]     price
    # @param [Hash]           options
    #
    # @option options [Integer] :order_id    —  ID заказа
    # @option options [Decimal] :points_rate — коэффициент конвертации рублей в баллы. Может принимать значение из полуинтервала (0,1].
    #                                          При отсутствии данного параметра, используется значение, указанное в настройках.
    #                                          Формат points_rate=0.45
    # @option options [true|false] :force_complete —  если true, транзакция считается подтвержденной несмотря на флаг в настройках.
    #                                                 Данный аттрибут может быть использован, например, в случае когда часть оплат
    #                                                 необходимо подтверждать, а про остальные известно что они уже подтверждены.
    #
    # @return [Sailplay::Purchase]
    def create_purchase(phone_or_user_id, price, options = {})
      self.client.create_purchase(phone_or_user_id, price, options)
    end

    # @param [Integer] order_id
    # @param [Hash]    options
    #
    # @option options [BigDecimal] :price
    def confirm_purchase(order_id, options = {})
      self.client.confirm_purchase(order_id, options)
    end


      # @param [String] gift_public_key
    def confirm_gift(gift_public_key)
      self.client.confirm_gift(gift_public_key)
    end

    def request(method, url, params)
      self.client.request(method, url, params)
    end
  end
end