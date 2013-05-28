require 'sailplay'

module Sailplay
  module Rails
    module ControllerMethods
      # Ex.: http://www.amazon.com/sailplay-listener/?gift_public_key=09kdhh472idgh785920kfa&gift_sku=4829&user_phone=79141003334
      def sailplay_listener
        # TODO: implement callback
      end

      private

      def authenticate_sailplay_user(phone, force_reload = false)
        session[:sailplay] = nil if force_reload

        if session[:sailplay] && session[:sailplay][:auth_expires] > Time.now
          sailplay_options[:auth_hash] = cookies[:sailplay_auth]
        else
          user = begin
            Sailplay.find_user(phone, :auth => true)
          rescue Sailplay::APIError
            Sailplay.create_user(phone, :auth => true) rescue nil
          end

          if user
            sailplay_options[:auth_hash] = user.auth_hash
            session[:sailplay] = {:auth_hash => user.auth_hash, :auth_expires => 3.days.from_now}
          end

          user
        end
      end

      def report_sailplay_purchase(user_phone_or_id, order_id, price)
        purchase = Sailplay.create_purchase(user_phone_or_id, price, :order_id => order_id)
        sailplay_options[:public_key] = purchase.public_key
      rescue Sailplay::Error => e
        logger.error "Error reporting purchase to Sailplay: #{e.message}"
      end
    end
  end
end