require 'sailplay/api/base'
require 'sailplay/api/gift'

module Sailplay
  class User < Base
    attr_accessor :id, :phone, :full_name, :points, :media_url, :available_gifts, :unavailable_gifts, :auth_hash

    # {
    #   user_phone: "79266054612",
    #   auth_hash: "1a159580bc111be0c288eb90afbce6f42ee48bba",
    #   user_points: 189,
    #   media_url: "http://d3257v5wstjx8h.cloudfront.net/media/"
    #   available_gifts: [
    #     {
    #       sku: 5,
    #       name: "Подарок 1",
    #       pic: "gifts/gift/b6e011188b74d3e0d838fbbace84de92.jpeg",
    #       pick_url: "http://sailplay.ru/api/v1/ecommerce/gifts/pick/?gift_id=15&user_phone=79266054612&token=239b3282621115d2e71bc844d546b7dea4385326&store_department_id=19",
    #       points: 55,
    #       id: 25
    #     }
    #   ],
    #   over_user_points_gifts: [
    #     {
    #       sku: 1,
    #       name: "Подарок 2",
    #       view_url: "http://sailplay.ru/gifts/view/97/",
    #       pic: "gifts/gift/83dd4abd6f13495f222113416103b716.jpg",
    #       points: 200,
    #       id: 27
    #     }
    #   ]
    # }
    def self.parse(json)
      Sailplay::User.new(
          :phone => json[:user_phone] || json[:phone],
          :points => json[:user_points] || json[:points],
          :full_name => json[:full_name],
          :media_url => json[:media_url],
          :auth_hash => json[:auth_hash],
          :available_gifts => (json[:available_gifts] || []).map {|gift_json| Gift.parse(gift_json)},
          :unavailable_gifts => (json[:over_user_points_gifts] || []).map {|gift_json| Gift.parse(gift_json)}
      )
    end

    def initialize(attrs = {})
      [:id, :phone, :full_name, :points, :media_url, :auth_hash, :available_gifts, :unavailable_gifts].each do |attr|
        instance_variable_set("@#{attr}", attrs[attr])
      end
    end
  end
end