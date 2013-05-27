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

    def logger
      Sailplay.logger
    end

    def request(method, url, params = {})
      execute_request(method, url, auth_params.merge(params))
    end

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

    private

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