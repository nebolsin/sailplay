require 'sailplay'
require 'sailplay/rails/controller_methods'
require 'sailplay/rails/helper'

module Sailplay
  module Rails
    def self.initialize
      if defined?(::ActionController::Base)
        ::ActionController::Base.send(:include, Sailplay::Rails::Client)
      end

      rails_logger = if defined?(::Rails.logger)
        ::Rails.logger
      elsif defined?(RAILS_DEFAULT_LOGGER)
        RAILS_DEFAULT_LOGGER
      end

      Sailplay.configure do |config|
        config.logger = rails_logger
      end
    end
  end
end

Sailplay::Rails.initialize