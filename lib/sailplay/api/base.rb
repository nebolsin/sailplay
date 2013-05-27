module Sailplay
  class Base
    attr_reader :store_id, :store_token

    attr_accessor :response


    def self.request(url, params = {})
      @response = Sailplay.client.request(url, params.merge(:store_department_id => @store_id, :token => @store_token))
    end
  end
end