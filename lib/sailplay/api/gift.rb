require 'sailplay/api/base'

module Sailplay
  class Gift < Base
    attr_accessor :id, :sku, :name, :pic, :view_url, :pick_url, :points

    #{
    #    sku: 5,
    #    name: "Подарок 1",
    #    pic: "gifts/gift/b6e011188b74d3e0d838fbbace84de92.jpeg",
    #    pick_url: "http://sailplay.ru/api/v1/ecommerce/gifts/pick/?gift_id=15&user_phone=79266054612...,
    #    points: 55,
    #    id: 25
    #}
    def self.parse(json)
      Sailplay::Gift.new(
          :id => json[:id],
          :sku => json[:sku],
          :name => json[:name],
          :pic => json[:pic],
          :view_url => json[:view_url],
          :pick_url => json[:pick_url],
          :points => json[:points]
      )
    end

    def initialize(attrs = {})
      [:id, :sku, :name, :pic, :view_url, :pick_url, :points].each do |attr|
        instance_variable_set("@#{attr}", attrs[attr])
      end
    end

  end
end