module Sailplay
  module Rails
    module Client
      def self.included(base)
        base.send :around_filter, :prepare_sailplay_options

        base.send :helper_method, :sailplay_client?, :render_sailplay_client
      end

      protected

      def assign_sailplay_user(user)
        sailplay_options(:origin_user_id => user.sailplay_user_id) if user.respond_to?(:sailplay_user_id)
        sailplay_options(:probable_user_phone => user.sailplay_phone) if user.respond_to?(:sailplay_user_id)
      end

      def sailplay_client?
        true
      end

      def render_sailplay_client(options = {})
        @_sailplay_client_fired = true
        result = sailplay_compile_template(sailplay_options.merge(options))

        if result.respond_to?(:html_safe)
          result.html_safe
        else
          result
        end
      end

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
            sailplay_options :auth_hash => user.auth_hash, :auth_expires => 3.days.from_now
          end
        end
      end

      def report_sailplay_purchase(user_id, order_id, price)
        purchase = Sailplay.create_purchase(user_id, price, :order_id => order_id)
        sailplay_options :transaction_key => purchase.public_key
        purchase
      rescue Sailplay::Error => e
        logger.error "Error reporting purchase to Sailplay: #{e.message}"
      end


      def sailplay_options(options = {})
        (@_sailplay_options ||= {}).merge! options
      end

      private

      def prepare_sailplay_options
        load_sailplay_options
        yield
        if @_sailplay_client_fired
          reset_sailplay_options
        end
        save_sailplay_options
      end

      def save_sailplay_options
        (session[:sailplay] ||= {}).merge! sailplay_options
      end

      def load_sailplay_options
        @_sailplay_options = session.delete :sailplay
      end

      def reset_sailplay_options
        @_sailplay_options = nil
        session[:sailplay] = nil
      end


      def sailplay_compile_template(options)
        template_options = {
          :file          => File.join(File.dirname(__FILE__), '..', '..', 'templates', 'sailplay_client'),
          :layout        => false,
          :use_full_path => false,
          :handlers      => [:erb],
          :locals        => {
            :host           => Sailplay.configuration.host,
            :api_path       => Sailplay.configuration.js_api_path,
            :store_id       => Sailplay.configuration.store_id,
            :position       => Sailplay.configuration.js_position.to_s.split('_'),
            :skin           => Sailplay.configuration.skin,
            :origin_user_id => '',
            :user_phone     => '',
            :auth_hash      => '',
            :public_key     => 'none',
            :link           => '',
            :pic            => ''
          }
        }

        template_options[:locals].merge!(options)

        case @template
          when ActionView::Template
            @template.render template_options
          else
            render_to_string template_options
        end
      end
    end
  end
end