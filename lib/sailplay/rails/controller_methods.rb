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
        return if phone.nil?

        if force_reload || (session[:sailplay] && session[:sailplay][:auth_expires] < Time.now)
          session[:sailplay] = nil
        end

        unless session[:sailplay]
          user = begin
            Sailplay.find_user(phone, :auth => true)
          rescue Sailplay::APIError
            Sailplay.create_user(phone, :auth => true) rescue nil
          end

          if user
            session[:sailplay] = {:auth_hash => user.auth_hash, :auth_expires => 3.days.from_now}
          end
        end

        sailplay_options[:auth_hash] = session[:sailplay][:auth_hash] if session[:sailplay]
      end

      def report_sailplay_purchase(user_id, order_id, price)
        purchase = Sailplay.create_purchase(user_id, price, :order_id => order_id)
        session[:sailplay_purchase_key] = purchase.public_key
        purchase
      rescue Sailplay::Error => e
        logger.error "Error reporting purchase to Sailplay: #{e.message}"
      end
    end
  end
end