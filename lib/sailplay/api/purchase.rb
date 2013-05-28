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
      Sailplay::Purchase.new(
        :id => json[:id],
        :order_id => json[:order_num],
        :price => json[:price],
        :points_delta => json[:points_delta],
        :complete_date => json[:complete_date],
        :public_key => json[:public_key]
      )
    end

    def initialize(options = {})
      [:id, :order_id, :price, :points_delta, :complete_date, :public_key].each do |attr|
        instance_variable_set("@#{attr}", options[attr])
      end
    end
  end
end