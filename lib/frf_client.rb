require 'net/http'
require 'base64'
require 'fileutils'

require 'json'
require 'rutils/datetime/datetime'

#class String
    #def to_json(*a)
        #'"' + self.gsub('\\', '\\\\\\').gsub('"', '\"') + '"'
    #end
#end

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

    def request(method, params = {})
        response = nil
        Net::HTTP.start 'friendfeed-api.com', 80 do |http|
            req = Net::HTTP::Get.new(construct_url(method, params))
            req.basic_auth(@user, @key) if @key
            response = http.request(req)
        end
        response = JSON.parse(response.body)
        response['errorCode'] && raise(RuntimeError, response['errorCode']) 
        response
    end

    def construct_url(method, params)
        "/v2/#{method}?" + params.map{|k, v| "#{k}=#{v}"}.join('&')
    end
    
    def self.extract_feed(user, key, feedname, path, start = 0)
        frf = new(user, key)
        s = start
        page = 100
        while true
            data = frf.feed(feedname, :start => s, :num => page)
            break if data['entries'].empty?
            puts "Loaded %i entries, starting from %i" % [page, s]
            
            le = nil
            data['entries'].each do |e|
                ename = e['url'].gsub("http://friendfeed.com/#{user}/", '').gsub("/", '__')
                name = File.join(path, ename + ".js")
                e['name'] = ename
                e['dateFriendly'] = parse_time(e['date']).strftime('%d %B %Y в %H:%M')
                (e['comments'] || []).each{|c| c['dateFriendly'] = parse_time(c['date']).strftime('%d %B %Y в %H:%M')}
                (e['likes'] || []).each{|c| c['dateFriendly'] = parse_time(c['date']).strftime('%d %B %Y в %H:%M')}
                e['likes'] && e['likes'] = e['likes'].sort_by{|l| l['date']}.reverse
                FileUtils.makedirs(File.dirname(name))
                File.write(name, e.to_json)
                le = e
            end
            puts le['dateFriendly']
            
            s += page
        end
    end
end
