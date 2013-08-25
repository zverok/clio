# encoding: utf-8
require 'simplehttp'
require 'base64'
require 'fileutils'

require 'json'
require 'rutils/datetime/datetime'

def parse_time(str)
    str =~ /(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)Z/
    Time.local($1, $2, $3, $4, $5, $6)
end

class FriendFeedClient
    def initialize(user, key, logger = nil)
        @user, @key = user, key
        @log = logger || SilenceLogger.new
        @pagesize = 100
    end

    attr_accessor :pagesize

    attr_reader :log
    
    def extract(feed, path, options = {})
        log.info "Загружаем #{feed}"
        
        # userpic
        userpic = extract_userpic(feed)
        File.write File.join(path, 'images', 'userpic.jpg'), userpic

        # extract entries
        start = options.delete(:start) || 0
        loaded = 0
        max = options.delete(:max_depth)
        
        while true
            page = extract_feed(feed, :start => start, :num => pagesize)
            
            break if page['entries'].empty?
            
            prev_last_entry, last_entry = nil
            
            page['entries'].each do |e|
                last_entry = process_entry(e)
                entry_path = File.join(path, 'data', 'entries', "#{last_entry['name']}.js")
                File.write(entry_path, last_entry.to_json)
            end
            
            log.info "Загружено %i записей, начиная с %i; дата самой старой — '%s'" % [page['entries'].size, start, last_entry['dateFriendly']]
            
            start += pagesize
            loaded += pagesize
            
            if max && !max.zero? && loaded >= max
                log.info "Загружено заданное количество записей (#{max}). Останавливаемся."
                break
            end
            
            if prev_last_entry == last_entry
                log.warn "Страница повторилась. Вероятно, наткнулись на ограничение FriendFeed. Останавливаемся."
                break
            end

            prev_last_entry = last_entry
        end

        true

    rescue RuntimeError => e
        case e.message
        when /Net::HTTPForbidden/
            log.error "Доступ запрещён: #{e.message.scan(%r{http://\S+}).flatten.first}"
        when /Net::HTTPUnauthorized/
            log.error "Авторизация не удалась (проверьте юзернейм и ремоут-ключ): #{e.message.scan(%r{http://\S+}).flatten.first}"
        else
            log.error "Ошибка: #{e.message}"
        end
        false
    end
    
    def self.extract_feed(user, key, feedname, path, start = 0)
        frf = new(user, key)
        frf.extract(feedname, path, start)
    end

    private

    def extract_feed(name, params)
        request("feed/#{name}", params)
    end
    
    def extract_userpic(user, size='large')
        raw_request("picture/#{user}", 'size' => size)
    end

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
    end

    def construct_url(method, params)
        "http://friendfeed-api.com/v2/#{method}?" + params.map{|k, v| "#{k}=#{v}"}.join('&')
    end

    def make_friendly_date(t)
        parse_time(t).strftime('%d %B %Y в %H:%M')
    end

    def process_entry(raw)
        raw.merge(
            'name' => raw['url'].gsub(%r{http://friendfeed\.com/[^/]+/}, '').gsub("/", '__'),
            'dateFriendly' => make_friendly_date(raw['date']),
            'comments' => (raw['comments'] || []).map{|comment|
                    comment.merge(
                        'dateFriendly' => make_friendly_date(comment['date'])
                    )
                },
            'likes' => (raw['likes'] || []).map{|like|
                    like.merge(
                        'dateFriendly' => make_friendly_date(like['date'])
                    )
                }.sort_by{|l| l['date']}.reverse
        )
    end
    
end
