# encoding: utf-8
require 'simplehttp'
require 'base64'
require 'fileutils'

require_relative './simplehttp_patch'

class FriendFeedClient
    def initialize(user, key)
        @user, @key = user, key
    end

    attr_reader :user

    def request(method, params = {})
        response = JSON.parse(raw_request(method, params))
        response['errorCode'] && raise(RuntimeError, response['errorCode']) 
        response
    end
    
    def raw_request(method, params = {})
        http = SimpleHttp.new construct_url(method, params)
        http.basic_authentication @user, @key
        
        # somehow internal SimpleHttp's redirection following fails
        http.register_response_handler(Net::HTTPRedirection){|request, response, shttp| 
            SimpleHttp.get response['location'] 
        }
        http.get
    #rescue RuntimeError => e
        #case e.message
        #when /Net::HTTPForbidden/
            #Clio.log.error "Доступ запрещён: #{e.message.scan(%r{http://\S+}).flatten.first}"
        #when /Net::HTTPUnauthorized/
            #Clio.log.error "Авторизация не удалась (проверьте юзернейм и ремоут-ключ): #{e.message.scan(%r{http://\S+}).flatten.first}"
        #else
            #Clio.log.error "Ошибка: #{e.message}"
        #end
        #raise
    end

    private
    
    def construct_url(method, params)
        params.empty? ?
            "http://friendfeed-api.com/v2/#{method}" :
            "http://friendfeed-api.com/v2/#{method}?" + params.map{|k, v| "#{k}=#{v}"}.join('&')
    end
end
