# encoding: utf-8
require 'fileutils'
require 'rest_client'

class RestClient::Exception
    attr_accessor :url
end

class FriendFeedClient
    def initialize(user, key)
        @user, @key = user, key
    end

    attr_reader :user

    def request(method, params = {})
        response = JSON.parse(raw_request(method, params).force_encoding('UTF-8'))
        response['errorCode'] && raise(RuntimeError, response['errorCode']) 
        response
    end
    
    def raw_request(method, params = {})
        url = construct_url(method)
        RestClient.get(url, params: params).body
    rescue RestClient::Exception => e
        e.url = url
        raise
    end

    private
    
    def construct_url(method)
        "http://#{@user}:#{@key}@friendfeed-api.com/v2/#{method}"
    end
end
