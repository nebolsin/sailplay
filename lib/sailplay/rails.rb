require 'sailplay'

module Sailplay
  module Rails
    def self.initialize
      if defined?(ActionController::Base)
        ActionController::Base.send(:include, Sailplay::Rails::Helper)
      end
    end
  end
end

Sailplay::Rails.initialize