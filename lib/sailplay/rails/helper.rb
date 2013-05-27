module Sailplay
  module Rails
    module Helper
      def self.included(base)
        base.send :helper_method, :sailplay_client
      end

      private

      def sailplay_options
        path = File.join File.dirname(__FILE__), '..', '..', 'templates', 'sailplay_client'

        options = {
            :file            => path,
            :layout          => false,
            :use_full_path   => false,
            :handlers        => [:erb],
            :locals          => {
                :host      => Sailplay.configuration.host,
                :api_path  => Sailplay.configuration.js_api_path,
                :store_id  => Sailplay.configuration.store_id,
                :position  => Sailplay.configuration.js_position.to_s.split('_'),
                :skin      => nil
            }
        }
      end
      
      def sailplay_client(opts = {})
        default_options = {
            :origin_user_id => '',
            :auth_hash => '',
            :public_key => 'none',
            :link => '',
            :pic => '',
            :skin => {}
        }

        options = sailplay_options
        options[:locals].merge!(default_options.merge(opts))

        result = sailplay_compile_template(options)

        if result.respond_to?(:html_safe)
          result.html_safe
        else
          result
        end
      end

      def sailplay_compile_template(options)
        case @template
          when ActionView::Template
            @template.render options
          else
            render_to_string options
        end
      end
    end
  end
end