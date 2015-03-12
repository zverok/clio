# encoding: utf-8
require 'simplehttp'
require 'base64'
require 'fileutils'

require 'json'

class FriendFeedClient
    def initialize(user, key)
        @user, @key = user, key
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

    private
    
    def construct_url(method, params)
        "http://friendfeed-api.com/v2/#{method}?" + params.map{|k, v| "#{k}=#{v}"}.join('&')
    end
end
__END__

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
        @lang = options.delete(:lang)
        
        if @lang == 'en'
            log.info "Loading #{feed}"
        else
            log.info "Загружаем #{feed}"
        end
        
        # userpic
        userpic = extract_userpic(feed)
        File.write File.join(path, 'images', 'userpic.jpg'), userpic

        # extract entries
        start = options.delete(:start) || 0
        loaded = 0
        max = options.delete(:max_depth)
        
        prev_last_entry, last_entry = nil
    
        while true
            page = extract_feed(feed, :start => start, :num => pagesize)
            
            break if page['entries'].empty?
            
            page['entries'].each do |e|
                last_entry = process_entry(e)
                entry_path = File.join(path, 'data', 'entries', "#{last_entry['name']}.js")
                File.write(entry_path, last_entry.to_json)
            end
            
            if @lang == 'en'
                log.info "%i entries loaded, starting with %i; oldest date is '%s'" % [page['entries'].size, start, last_entry['dateFriendly']]
            else
                log.info "Загружено %i записей, начиная с %i; дата самой старой — '%s'" % [page['entries'].size, start, last_entry['dateFriendly']]
            end
            
            start += pagesize
            loaded += pagesize
            
            if max && !max.zero? && loaded >= max
                if @lang == 'en'
                    log.info "Maximum entry count loaded (#{max}). Stop."
                else
                    log.info "Загружено заданное количество записей (#{max}). Останавливаемся."
                end
                break
            end
            
            if prev_last_entry && prev_last_entry['date'] == last_entry['date']
                if @lang == 'en'
                    log.warn "Pages repeating. Possibly FriendFeed limits exceeded. Stop."
                else
                    log.warn "Страница повторилась. Вероятно, наткнулись на ограничение FriendFeed. Останавливаемся."
                end
                break
            end

            prev_last_entry = last_entry
        end

        true

    rescue RuntimeError => e
        case e.message
        when /Net::HTTPForbidden/
            if @lang == 'en'
                log.error "Access forbidden: #{e.message.scan(%r{http://\S+}).flatten.first}"
            else
                log.error "Доступ запрещён: #{e.message.scan(%r{http://\S+}).flatten.first}"
            end
        when /Net::HTTPUnauthorized/
            if @lang == 'en'
                log.error "Authorization fail (check username and key): #{e.message.scan(%r{http://\S+}).flatten.first}"
            else
                log.error "Авторизация не удалась (проверьте юзернейм и ремоут-ключ): #{e.message.scan(%r{http://\S+}).flatten.first}"
            end
        else
            if @lang == 'en'
                log.error "Error: #{e.message}"
            else
                log.error "Ошибка: #{e.message}"
            end
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
        if @lang == 'en'
            parse_time(t).strftime('%B %d, %Y at %H:%M')
        else
            parse_time(t).strftime('%d %B %Y в %H:%M')
        end
    end

    def process_entry(raw)
        raw.merge(
            'name' => raw['url'].gsub(%r{http://friendfeed\.com/[^/]+/}, '').gsub(%r{/[^/]+}, ''),
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
