require 'multi_json'
require 'sailplay/error'
require 'sailplay/response/sanitizer'

module Sailplay
  class Response
    include Sanitizer

    attr_reader :code, :body, :json
    attr_reader :success, :payload, :error_message

    def initialize(response)
      @code, @body = response.code, response.body
      @json        = MultiJson.load(@body, :symbolize_keys => true)

      extract_and_sanitize_payload! if @json
    rescue MultiJson::DecodeError
      raise APIError.new("Invalid response object from API: #{@body.inspect} (HTTP response code was #{@code})", @code, @body)
    end

    def error?
      !success?
    end

    private

    def extract_status!
      @success = @json && @json[:status] == 'ok'
    end

    def extract_and_sanitize_payload!
      @payload = {}
      @json.each do |key, value|
        case key
          when :status
            @status = (value == 'ok')
          when :message
            @error_message = value
          when :user, :purchase
            @payload[key] = send("sanitize_#{key}", value)
          else
            @payload[key] = value
        end
      end
    end
  end
end