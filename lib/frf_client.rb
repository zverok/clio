require 'typhoeus'
require 'json'
require 'base64'

require 'rutils/datetime/datetime'

class String
    def to_json
        '"' + self.gsub('\\', '\\\\\\').gsub('"', '\"') + '"'
    end
end

def parse_time(str)
    str =~ /(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)Z/
    Time.local($1, $2, $3, $4, $5, $6)
end

class FriendFeedClient
    def initialize(user, key)
        @headers = if key
            {"Authorization" => ("Basic " + Base64.b64encode("#{user}:#{key}"))}
        else
            {}
        end
    end
    
    def feed(name, params)
        request("feed/#{name}", params)
    end

    def request(method, params = {})
        url = construct_url(method, params)
        response = Typhoeus::Request.get(url, :headers => @headers)
        response = JSON.parse(response.body)
        response['errorCode'] && raise(RuntimeError, response['errorCode']) 
        response
    end

    def construct_url(method, params)
        "http://friendfeed-api.com/v2/#{method}?" + params.map{|k, v| "#{k}=#{v}"}.join('&')
    end
    
    def self.extract_feed(user, key, feedname, path)
        frf = new(user, key)
        s = 0
        page = 100
        while true
            data = frf.feed(feedname, :start => s, :num => page)
            break if data['entries'].empty?
            puts "Loaded %i entries, starting from %i" % [page, s]
            
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
            end
            s += page
        end
    end
end
