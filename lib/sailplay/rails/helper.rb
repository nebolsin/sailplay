module Sailplay
  module Rails
    module Helper
      def self.included(base)
        base.send :helper_method, :sailplay_client
      end

      private

      def sailplay_options
        @_sailplay_options ||= {}
      end

      def sailplay_client(options = {})
        result = sailplay_compile_template(sailplay_options.merge(options))

        if result.respond_to?(:html_safe)
          result.html_safe
        else
          result
        end
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
            :origin_user_id => '',
            :user_phone     => '',
            :auth_hash      => '',
            :public_key     => 'none',
            :link           => '',
            :pic            => '',
            :skin           => {}
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