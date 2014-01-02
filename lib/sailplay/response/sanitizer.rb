module Sailplay
  class Response
    module Sanitizer
      # {
      #   user_phone: "79266054612",
      #   auth_hash: "1a159580bc111be0c288eb90afbce6f42ee48bba",
      #   user_points: 189,
      #   media_url: "http://d3257v5wstjx8h.cloudfront.net/media/"
      #   available_gifts: [ {{...gift#1...}, {...gift#2...}, ... ],
      #   over_user_points_gifts: [{...gift#7...}, {...}]
      # }
      def sanitize_user(json)
        json && {
            :phone             => json[:user_phone] || json[:phone],
            :points            => json[:user_points] || json[:points],
            :full_name         => json[:full_name],
            :media_url         => json[:media_url],
            :auth_hash         => json[:auth_hash],
            :available_gifts   => (json[:available_gifts] || []).map { |gift_json| sanitize_gift(gift_json) },
            :unavailable_gifts => (json[:over_user_points_gifts] || []).map { |gift_json| sanitize_gift(gift_json) }
        }
      end


      # {
      #   "complete_date":"2013-01-25T00:31:42.642",
      #   "price":"10",
      #   "id":8,
      #   "points_delta":4,
      #   "public_key":";ao08rj3tj09fu9jkwer20393urjflshg54h",
      #   "order_num":87573,
      # }
      def sanitize_purchase(json)
        json && {
            :id            => json[:id],
            :order_id      => json[:order_num],
            :price         => json[:price],
            :points_delta  => json[:points_delta],
            :complete_date => json[:complete_date],
            :public_key    => json[:public_key]
        }
      end

      #{
      #    sku: 5,
      #    name: "Подарок 1",
      #    pic: "gifts/gift/b6e011188b74d3e0d838fbbace84de92.jpeg",
      #    pick_url: "http://sailplay.ru/api/v1/ecommerce/gifts/pick/?gift_id=15&user_phone=79266054612...,
      #    points: 55,
      #    id: 25
      #}
      def sanitize_gift(json)
        json && {
            :id       => json[:id],
            :sku      => json[:sku],
            :name     => json[:name],
            :pic      => json[:pic],
            :view_url => json[:view_url],
            :pick_url => json[:pick_url],
            :points   => json[:points]
        }
      end
    end
  end
end
