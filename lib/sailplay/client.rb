require 'rest-client'
require 'multi_json'
require 'sailplay/configuration'
require 'sailplay/error'
require 'sailplay/response'

module Sailplay
  class Client
    attr_reader :protocol,
                :host,
                :port,
                :endpoint,
                :secure,
                :connection_options,
                :store_id,
                :store_key,
                :store_pin

    alias_method :secure?, :secure

    def initialize(options = {})
      [ :protocol,
        :host,
        :port,
        :endpoint,
        :secure,
        :connection_options,
        :store_id,
        :store_key,
        :store_pin
      ].each do |option|
        instance_variable_set("@#{option}", options[option])
      end
    end

    # @param [String] phone
    # @param [Hash]   options
    #
    # @option options [true|false] :auth — authenticate user
    #
    # @return [Sailplay::User]
    def create_user(phone, options = {})
      params = {:user_phone => phone}
      params[:extra_fields] = 'auth_hash' if options[:auth]

      response = request(:get, '/users/reg', :user_phone => phone)
      if response.success?
        User.parse(response.data)
      else
        raise APIError, "Cannot create user '#{phone}': #{response.error_message}"
      end
    end

    # @param [String] phone
    # @param [Hash]   options
    #
    # @option options [true|false] :auth — authenticate user
    #
    # @return [Sailplay::User]
    def find_user(phone, options = {})
      params = {:user_phone => phone}
      params[:extra_fields] = 'auth_hash' if options[:auth]

      response = Sailplay.request(:get, '/users/points-info', params)
      if response.success?
        User.parse(response.data)
      else
        raise APIError, "Cannot find a user '#{phone}': #{response.error_message}"
      end
    end

    # options[:points_rate]    —  коэффициент конвертации рублей в баллы. Может принимать значение из полуинтервала (0,1].
    #                             При отсутствии данного параметра, используется значение, указанное в настройках.
    #                             Формат points_rate=0.45
    # options[:force_complete] —  если true, транзакция считается подтвержденной несмотря на флаг в настройках.
    #                             Данный аттрибут может быть использован, например, в случае когда часть оплат
    #                             необходимо подтверждать, а про остальные известно что они уже подтверждены.
    # options[:order_id]       —  ID заказа
    #
    # @return [Sailplay::Purchase]
    def create_purchase(user_id, price, options = {})
      params = {:price => price, :origin_user_id => user_id}

      params[:user_phone] = options[:phone] if options[:phone]
      params[:points_rate] = options[:points_rate] if options[:points_rate]
      params[:force_complete] = options[:force_complete] if options[:force_complete]
      params[:order_num] = options[:order_id] if options[:order_id]

      params[:fields] = [:public_key, options[:order_id] && :order_num].compact.join(',')

      response = Sailplay.request(:get, '/purchases/new', params)

      if response.success?
        Purchase.parse(response.data)
      else
        raise APIError, "Cannot create a purchase: #{response.error_message}"
      end
    end

    # @param [Integer] order_id
    # @param [Hash]    options
    #
    # @option options [BigDecimal] :price
    def confirm_purchase(order_id, options = {})
      params = {:order_num => order_id}
      params[:new_price] = options[:price] if options[:price]

      response = request(:get, '/purchases/confirm', params)

      if response.success?
        Purchase.parse(response.data)
      else
        raise APIError, "Cannot confirm a purchase: #{response.error_message}"
      end
    end

    # @param [String] gift_public_key
    def confirm_gift(gift_public_key)
      params = {:gift_public_key => gift_public_key}
      response = request(:get, '/ecommerce/gifts/commit-transaction', params)

      if response.success?
      else
        raise APIError, "Cannot confirm a gift: #{response.error_message}"
      end
    end

    def request(method, url, params = {})
      execute_request(method, url, auth_params.merge(params))
    end

    def logger
      Sailplay.logger
    end

    private

    def auth_params
      {:store_department_id => store_id, :token => api_token}
    end

    def api_url(url = '')
      URI.parse("#{protocol}://#{host}:#{port}").merge("#{endpoint}/#{url}").to_s
    end

    def api_token
      @api_token ||= login
    end

    def login
      raise ConfigurationError, 'Missing client configuration: ' +
          'please check that store_id, store_key and pin_code are ' +
          'configured' unless credentials?

      response = execute_request(:get, 'login', credentials)

      if response.success?
        response.data[:token]
      else
        raise AuthenticationError.new("Cannot authenticate on Sailplay. Check your config. (Response: #{response})")
      end
    end

    def credentials
      {
          :store_department_id => @store_id,
          :store_department_key => @store_key,
          :pin_code => @store_pin
      }
    end

    def credentials?
      credentials.values.all?
    end

    def execute_request(method, url, params = {})
      logger.debug(self.class) {"Starting #{method} request to #{url} with #{params.inspect}"}
      url = api_url(url)
      headers = @connection_options[:headers].merge(:params => params)

      request_opts = {:method => method, :url => url, :headers => headers}

      begin
        response = RestClient::Request.execute(request_opts)
      rescue RestClient::ExceptionWithResponse => e
        if e.http_code && e.http_body
          handle_api_error(e.http_code, e.http_body)
        else
          handle_restclient_error(e)
        end
      rescue RestClient::Exception, SocketError, Errno::ECONNREFUSED => e
        handle_restclient_error(e)
      end


      http_code, http_body = response.code, response.body

      logger.debug(self.class) {"\t HTTP Code -> #{http_code}"}
      #logger.debug(self.class) {"\t HTTP Body -> #{http_body}"}

      begin
        json_body = MultiJson.load(http_body, :symbolize_keys => true)
      rescue MultiJson::DecodeError
        raise APIError.new("Invalid response object from API: #{http_body.inspect} (HTTP response code was #{http_code})", http_code, http_body)
      end

      #logger.debug(self.class) {"\t JSON Body -> #{json_body}"}

      response = Response.new(json_body)

      logger.debug(self.class) {"\t Valid     -> #{response.success?}"}
      logger.debug(self.class) {"\t Payload   -> #{response.data}"}

      response
    end

    def handle_restclient_error(e)
      case e
        when RestClient::ServerBrokeConnection, RestClient::RequestTimeout
          message = "Could not connect to Sailplay (#{endpoint}). " +
              "Please check your internet connection and try again. " +
              "If this problem persists, let us know at support@sailplay.ru."
        when SocketError
          message = "Unexpected error communicating when trying to connect to Sailplay. " +
              "HINT: You may be seeing this message because your DNS is not working. " +
              "To check, try running 'host sailplay.ru' from the command line."
        else
          message = "Unexpected error communicating with Sailplay. " +
              "If this problem persists, let us know at support@sailplay.ru."
      end
      message += "\n\n(Network error: #{e.message})"
      raise APIConnectionError, message
    end

    def handle_api_error(http_code, http_body)
      begin
        error_obj = MultiJson.load(http_body, :symbolize_keys => true)
        message = error_obj[:message]
      rescue MultiJson::DecodeError
        message = "Invalid response object from API: #{http_body.inspect} (HTTP response code was #{http_code})"
        raise APIError.new(message, http_code, http_body)
      end

      case http_code
        when 400, 404 then
          raise InvalidRequestError.new(message, http_code, http_body, error_obj)
        when 401
          raise AuthenticationError.new(message, http_code, http_body, error_obj)
        else
          raise APIError.new(message, http_code, http_body, error_obj)
      end
    end

  end
end