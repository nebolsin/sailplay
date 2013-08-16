require 'sailplay/api/base'

module Sailplay
  class Purchase < Base
    attr_accessor :id, :order_id, :price, :points_delta, :complete_date, :public_key
    attr_accessor :user

    #{
    #    "complete_date":"2013-01-25T00:31:42.642",
    #    "price":"10",
    #    "id":8,
    #    "points_delta":4,
    #    "public_key":";ao08rj3tj09fu9jkwer20393urjflshg54h",
    #    "order_num":87573,
    #}
    def self.parse(json)
      purchase_json = json[:purchase]
      purchase = Sailplay::Purchase.new(
        :id => purchase_json[:id],
        :order_id => purchase_json[:order_num],
        :price => purchase_json[:price],
        :points_delta => purchase_json[:points_delta],
        :complete_date => purchase_json[:complete_date],
        :public_key => purchase_json[:public_key]
      )

      if user_json = json[:user]
        purchase.user = User.parse(user_json)
      end

      purchase
    end

    def initialize(options = {})
      [:id, :order_id, :price, :points_delta, :complete_date, :public_key].each do |attr|
        instance_variable_set("@#{attr}", options[attr])
      end
    end
  end
end