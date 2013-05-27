module Sailplay
  class Response
    attr_reader :raw_data, :data, :error_message

    def initialize(json_body)
      @raw_data = json_body

      if @raw_data && @raw_data[:status] == 'ok'
        @success = true
        @data = @raw_data.reject {|k, v| k == :status}
      else
        @success = false
        @error_message = @raw_data[:message]
      end
    end

    def success?
      @success
    end

    def error?
      !success?
    end
  end
end