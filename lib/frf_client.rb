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
    def initialize(user, key)
        @user, @key = user, key
    end
    
    def feed(name, params)
        request("feed/#{name}", params)
    end
    
    def userpic(user, size='large')
        raw_request("picture/#{user}", 'size' => size)
    end

    def request(method, params = {})
        response = JSON.parse(raw_request(method, params))
        response['errorCode'] && raise(RuntimeError, response['errorCode']) 
        response
    end
    
    def raw_request(method, params = {})
        http = SimpleHttp.new construct_url(method, params)
        http.basic_authentication @user, @key if @key
        
        # somehow internal SimpleHttp's redirection following fails
        http.register_response_handler(Net::HTTPRedirection){|request, response, shttp| 
	 		SimpleHttp.get response['location'] 
	 	}
        http.get
    end

    def construct_url(method, params)
        #"/v2/#{method}?" + params.map{|k, v| "#{k}=#{v}"}.join('&')
        "http://friendfeed-api.com/v2/#{method}?" + params.map{|k, v| "#{k}=#{v}"}.join('&')
    end
    
    def self.extract_feed(user, key, feedname, path, start = 0)
        frf = new(user, key)
        
        # extract userpic
        userpic = frf.userpic(user)
        File.write File.join(path, 'images', 'userpic.jpg'), userpic
        
        # extract entries
        s = start
        page = 100
        while true
            data = frf.feed(feedname, :start => s, :num => page)
            break if data['entries'].empty?
            puts "Loaded %i entries, starting from %i" % [page, s]
            
            le = nil
            data['entries'].each do |e|
                ename = e['url'].gsub("http://friendfeed.com/#{user}/", '').gsub("/", '__')
                name = File.join(path, 'data', 'entries', ename + ".js")
                e['name'] = ename
                e['dateFriendly'] = parse_time(e['date']).strftime('%d %B %Y в %H:%M')
                (e['comments'] || []).each{|c| c['dateFriendly'] = parse_time(c['date']).strftime('%d %B %Y в %H:%M')}
                (e['likes'] || []).each{|c| c['dateFriendly'] = parse_time(c['date']).strftime('%d %B %Y в %H:%M')}
                e['likes'] && e['likes'] = e['likes'].sort_by{|l| l['date']}.reverse
                File.write(name, e.to_json)
                le = e
            end
            puts le['dateFriendly']
            
            s += page
        end
    end
end
