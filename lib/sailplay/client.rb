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
      [:protocol,
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

    def request(method, url, params = {})
      Sailplay::Response.new execute_request(method, url, auth_params.merge(params))
    end


    # @param [String] phone
    # @param [Hash]   options
    #
    # @option options [true|false] :auth — authenticate user
    #
    # @return [Sailplay::User]
    def create_user(phone, options = {})
      params                = {:user_phone => phone}
      params[:extra_fields] = 'auth_hash' if options[:auth]

      response = request(:get, '/v1/users/reg/', :user_phone => phone)

      handle_response response, "Cannot create user '#{phone}': #{response.error_message}"
    end

    # @param [String] user_id
    # @param [Hash]   options
    #
    # @option options [true|false] :auth — authenticate user
    #
    # @return [Hash]
    def find_user(user_id, options = {})
      params                = {:origin_user_id => user_id}
      params[:user_phone]   = options[:phone] if options[:phone]
      params[:extra_fields] = 'auth_hash' if options[:auth]
      params[:history]      = '1' if options[:history]

      response = request(:get, '/v1/users/points-info/', params)
      handle_response response, "Cannot find a user '#{user_id}': #{response.error_message}"
    end

    # options[:points_rate]    —  коэффициент конвертации рублей в баллы. Может принимать значение из полуинтервала (0,1].
    #                             При отсутствии данного параметра, используется значение, указанное в настройках.
    #                             Формат points_rate=0.45
    # options[:force_complete] —  если true, транзакция считается подтвержденной несмотря на флаг в настройках.
    #                             Данный аттрибут может быть использован, например, в случае когда часть оплат
    #                             необходимо подтверждать, а про остальные известно что они уже подтверждены.
    # options[:order_id]       —  ID заказа
    #
    # @return [Hash] :user     —  @see Sailplay::Response#sanitize_user
    def create_purchase(user_id, price, options = {})
      params                  = {:price => price, :origin_user_id => user_id}

      params[:user_phone]     = options[:phone] if options[:phone]
      params[:points_rate]    = options[:points_rate] if options[:points_rate]
      params[:force_complete] = options[:force_complete] if options[:force_complete]
      params[:order_num]      = options[:order_id] if options[:order_id]
      params[:l_date]         = options[:date].to_i if options[:date]

      params[:fields] = [:public_key, options[:order_id] && :order_num].compact.join(',')

      response = request(:get, '/v1/purchases/new', params)

      handle_response response, "Cannot create a purchase: #{response.error_message}"
    end

    # @param [Integer] order_id
    # @param [Hash]    options
    #
    # @option options [BigDecimal] :price
    def confirm_purchase(order_id, options = {})
      params             = {:order_num => order_id}
      params[:new_price] = options[:price] if options[:price]

      response = request(:get, '/v1/purchases/confirm', params)

      handle_response response, "Cannot confirm a purchase: #{response.error_message}"
    end

    # @param [String] gift_public_key
    def confirm_gift(gift_public_key)
      params   = {:gift_public_key => gift_public_key}
      response = request(:get, '/v1/ecommerce/gifts/commit-transaction', params)

      handle_response response, "Cannot confirm a gift: #{response.error_message}"
    end

    # @param [String]  user_id    origin user id
    # @param [Integer] points     amount of points to deposit to the user's account
    # @param [String]  comment
    def add_points(user_id, points, comment = nil)
      params   = {:origin_user_id => user_id, :points => points, :comment => comment}
      response = request(:get, '/v2/points/add', params)

      handle_response response, "Cannot add points: #{response.error_message}"
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
      raise ConfigurationError,
            'Missing client configuration: please check that store_id, store_key and pin_code are configured' unless credentials?

      response =  Sailplay::Response.new(execute_request(:get, '/v1/login', credentials))
      payload = response.payload

      payload[:token] or raise AuthenticationError, "Cannot authenticate on Sailplay. Check your config. (Response: #{response})"
    end

    def credentials
      {
          :store_department_id  => @store_id,
          :store_department_key => @store_key,
          :pin_code             => @store_pin
      }
    end

    def credentials?
      credentials.values.all?
    end

    def execute_request(method, url, params = {})
      logger.debug(self.class) { "Starting #{method} request to #{url} with #{params.inspect}" }

      RestClient::Request.execute(
          :method  => method,
          :url     => api_url(url),
          :headers => connection_options[:headers].merge(:params => params)
      )

    rescue RestClient::ExceptionWithResponse => e
      e.http_code && e.http_body ?
          handle_api_error(e.http_code, e.http_body) :
          handle_restclient_error(e)
    rescue RestClient::Exception, SocketError, Errno::ECONNREFUSED => e
      handle_restclient_error(e)
    end

    def handle_response(response, message = nil)
      message ||= response.error_message
      response.payload or raise APIError, message
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
      raise Sailplay::APIConnectionError, message
    end

    def handle_api_error(http_code, http_body)
      begin
        error_obj = MultiJson.load(http_body, :symbolize_keys => true)
        message   = error_obj[:message]
      rescue MultiJson::DecodeError
        message = "Invalid response object from API: #{http_body.inspect} (HTTP response code was #{http_code})"
        raise Sailplay::APIError.new(message, http_code, http_body)
      end

      case http_code
        when 400, 404 then
          raise Sailplay::InvalidRequestError.new(message, http_code, http_body, error_obj)
        when 401
          raise Sailplay::AuthenticationError.new(message, http_code, http_body, error_obj)
        else
          raise Sailplay::APIError.new(message, http_code, http_body, error_obj)
      end
    end
  end
end
