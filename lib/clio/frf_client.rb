# encoding: utf-8
require 'fileutils'
require 'rest_client'

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
        RestClient.get(construct_url(method), params: params).body
    end

    private
    
    def construct_url(method)
        "http://#{@user}:#{@key}@friendfeed-api.com/v2/#{method}"
    end
end
