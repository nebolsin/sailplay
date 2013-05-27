require 'sailplay/api/base'

module Sailplay
  class Gift < Base
    #{
    #    sku: 5,
    #    name: "Подарок 1",
    #    pic: "gifts/gift/b6e011188b74d3e0d838fbbace84de92.jpeg",
    #    pick_url: "http://sailplay.ru/api/v1/ecommerce/gifts/pick/?gift_id=15&user_phone=79266054612...,
    #    points: 55,
    #    id: 25
    #}

    attr_accessor :id, :sku, :name, :pic, :view_url, :pick_url, :points

    def initialize(options = {})
      @id = options[:id]
      @name = options[:name]
      @pic = options[:pic]
      @view_url = options[:view_url]
      @pick_url = options[:pick_url]
      @points = options[:points]
    end
  end
end