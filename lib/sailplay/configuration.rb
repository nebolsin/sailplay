require 'logger'

module Sailplay
  class Configuration
    OPTIONS = [:host, :port, :secure, :endpoint, :connection_options, :store_id, :store_key, :store_pin, :logger]


    # The host to connect to (defaults to sailplay.ru).
    attr_accessor :host

    # The port on which Sailplay API server runs (defaults to 443 for secure
    # connections, 80 for insecure connections).
    attr_accessor :port

    # Url prefix for API (defaults to /api)
    attr_accessor :endpoint

    # +true+ for https connections, +false+ for http connections.
    attr_accessor :secure

    attr_accessor :connection_options
    attr_accessor :store_id
    attr_accessor :store_key
    attr_accessor :store_pin

    attr_accessor :logger

    # JS client configuration
    attr_accessor :js_api_path

    # one of :top_left, :top_right, :center_left, :center_right, :bottom_left, :bottom_right
    attr_accessor :js_position

    # {
    #   :buttonText => 'Text', :buttonBgGradient => ["#78bb44", "#367300"], :buttonFontSize => '9px',
    #   :picUrl => "http://some.url", :bgColor => '#ffffff', :borderColor => '#ffffff', :textColor => '#300c2f',
    #   :pointsColor => '#c81750', :buttonTextColor => '#ffffff'
    # }
    attr_accessor :skin


    DEFAULT_CONNECTION_OPTIONS = {
        :headers => {
            :accept => 'application/json',
            :user_agent => "Sailplay Ruby Gem (#{Sailplay::VERSION})"
        }
    }

    alias_method :secure?, :secure

    def initialize
      @host =     'sailplay.ru'
      @secure =   true
      @endpoint = '/api'

      @js_api_path = 'static/js/sailplay.js'
      @js_position = :top_right

      @skin = {}

      @connection_options = DEFAULT_CONNECTION_OPTIONS.dup
    end

    # Allows config options to be read like a hash
    #
    # @param [Symbol] option Key for a given attribute
    def [](option)
      send(option)
    end

    # Returns a hash of all configurable options
    def to_hash
      OPTIONS.inject({}) do |hash, option|
        hash[option.to_sym] = self.send(option)
        hash
      end
    end

    def port
      @port || default_port
    end

    # Determines whether protocol should be "http" or "https".
    # @return [String] Returns +"http"+ if you've set secure to +false+ in
    # configuration, and +"https"+ otherwise.
    def protocol
      if secure?
        'https'
      else
        'http'
      end
    end

    def logger
      @logger ||= begin
        log = Logger.new($stdout)
        log.level = Logger::INFO
        log
      end
    end

    private

    # Determines what port should we use for sending notices.
    # @return [Fixnum] Returns 443 if you've set secure to true in your
    # configuration, and 80 otherwise.
    def default_port
      if secure?
        443
      else
        80
      end
    end
  end
end