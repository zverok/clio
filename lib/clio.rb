# encoding: utf-8
require 'logger'

require_relative './clio/core_ext'
require_relative './clio/log_utils'
require_relative './clio/frf_client'
require_relative './clio/feed_context'

class Clio
    def self.valid?(user, key)
        FriendFeedClient.new(user, key).request('validate')
        true
    rescue RuntimeError => e
        if e.message.include?('Net::HTTPUnauthorized')
            false
        else
            raise
        end
    end

    # FIXME: надо для сервера, но как-то неаккуратненько
    def self.feed_info(user, key, feed = nil)
        FriendFeedClient.new(user, key).request("feedinfo/#{feed || user}")
    end
    
    def initialize(options)
        @options = options.dup
        @client = make_client if need_client?
        @base_path = File.expand_path(File.join(File.dirname(__FILE__), '..'))
        @templates_path = File.join(base_path, 'templates')
        @result_path = options[:path] || File.join(@base_path, 'result')
        @feed_names = options[:feeds] || [options[:user]].compact

        @feed_names.empty? and
            fail("Не заданы фиды для обработки (опция --feeds или --user)")

        @log = Logger.new(options[:log] || STDOUT).tap{|l|
            l.formatter = PrettyFormatter.new
        }

        #if opts.dates?
            #path = File.join(path, Time.now.strftime('%Y-%m-%d'))
        #end
    end

    attr_reader :options, :client, :log,
                :base_path, :templates_path, :result_path,
                :feed_names

    def run!
        feed_names.each do |name|
            context = FeedContext.new(self, name)

            #extract_feed? and context.extract_feed!

            context.reload_entries!

            extract_images? and [context.extract_pictures!, context.extract_userpics!]

            #context.index!
            #context.convert!
        end
    end

    def feed_info(feed_name = nil)
        client.request("feedinfo/#{feed_name || user}")
    end

    def user
        options[:user]
    end

    private

    def need_client?
        !options[:indexonly]
    end

    def extract_feed?
        !options[:indexonly]
    end

    def extract_images?
        !options[:indexonly] &&  !options[:noimages]
    end

    def make_client
        options[:user] && options[:key] or
            fail ("Не указан пользователь или ключ (опции --user и --key)")
            
        FriendFeedClient.new(options.fetch(:user), options.fetch(:key))
    end
end
