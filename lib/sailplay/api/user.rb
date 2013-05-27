require 'sailplay/api/base'
require 'sailplay/api/gift'
require 'sailplay/api/purchase'

require 'sailplay/error'

module Sailplay
  class User < Base
    attr_accessor :id, :phone, :full_name, :points, :media_url, :available_gifts, :unavailable_gifts, :auth_hash


    def self.parse(json)
      Sailplay::User.new(
          :phone => json[:user_phone],
          :full_name => json[:full_name],
          :points => json[:user_points],
          :media_url => json[:media_url],
          :auth_hash => json[:auth_hash],
          :available_gifts => (json[:available_gifts] || []).map {|gift_json| Gift.new(gift_json)},
          :unavailable_gifts => (json[:over_user_points_gifts] || []).map {|gift_json| Gift.new(gift_json)}
      )
    end

    # options[:auth]         —  если true, то будет произведена аутентификация пользователя и получен auth_hash
    def self.create!(phone, options = {})
      params = {:user_phone => phone}
      params[:extra_fields] = 'auth_hash' if options[:auth]

      response = Sailplay.request(:get, '/users/reg', :user_phone => phone)
      if response.success?
        User.parse(response.data)
      else
        raise APIError, "Cannot create user '#{phone}': #{response.error_message}"
      end
    end

    # options[:auth]         —  если true, то будет произведена аутентификация пользователя и получен auth_hash
    def self.find(phone, options = {})
      params = {:user_phone => phone}
      params[:extra_fields] = 'auth_hash' if options[:auth]

      response = Sailplay.request(:get, '/users/points-info', params)
      if response.success?
        User.parse(response.data)
      else
        raise APIError, "Cannot find a user '#{phone}': #{response.error_message}"
      end
    end

    # options[:fields]         —  дополнительные поля, которые будут в JSON ответе. Дополнительные поля перечисляются
    #                             через запятую и могут принимать следующие значения: public_key, order_num
    # options[:points_rate]    —  коэффициент конвертации рублей в баллы. Может принимать значение из полуинтервала (0,1].
    #                             При отсутствии данного параметра, используется значение, указанное в настройках.
    #                             Формат points_rate=0.45
    # options[:force_complete] —  если true, транзакция считается подтвержденной несмотря на флаг в настройках.
    #                             Данный аттрибут может быть использован, например, в случае когда часть оплат
    #                             необходимо подтверждать, а про остальные известно что они уже подтверждены.
    # options[:origin_user_id] —  ID (или его любой аналог) пользователя в вашей системе. Используется в случае если не
    #                             известен номер телефона пользователя. В качестве данного параметра, вы можете
    #                             использовать e­mail пользователя, либо его ID, либо любую уникальную хэш­функци
    #                             ю от параметров данного пользователя.
    def create_purchase!(price, options = {})
      params = {:price => price}
      if phone
        params[:user_phone] = phone
      elsif id
        params[:origin_user_id] = id
      else
        raise APIError, "Cannot create a purchase without user's phone or id"
      end

      params[:points_rate] = options[:points_rate] if options[:points_rate]
      params[:force_complete] = options[:force_complete] if options[:force_complete]
      params[:order_num] = options[:order_id] if options[:order_id]

      extra_fields = [options[:auth] == true && :public_key, options[:order_id] && :order_num].compact
      params[:fields] = extra_fields.join(',') unless extra_fields.empty?

      response = Sailplay.request(:get, '/purchases/new', params)

      if response.success?
        self.phone ||= response.data[:user][:phone]
        self.full_name ||= response.data[:user][:full_name]
        self.points = response.data[:user][:points]

        purchase = Purchase.new(response.data[:purchase])
        purchase.user = self
        purchase
      else
        raise APIError, "Cannot create a purchase': #{response.error_message}"
      end
    end

    def initialize(attrs = {})
      [:id, :phone, :full_name, :points, :media_url, :auth_hash, :available_gifts, :unavailable_gifts].each do |attr|
        instance_variable_set("@#{attr}", attrs[attr])
      end
    end
  end
end