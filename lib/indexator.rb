require 'json'
require 'core_ext'

def parse_time(str)
    str =~ /(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)Z/
    Time.local($1, $2, $3, $4, $5, $6)
end

def extract_hashtags(str)
    str.scan(%r{<a href="http://friendfeed.com/search\?q=[^>]+>#(.+?)</a>}).flatten.map{|ht| ht.gsub('_', ' ')}
end

class Index
    def initialize
        @rows = Hash.new{|h, k| h[k] = {'descriptor' => k, 'entries' => []} }
    end
    
    def put(entry)
        parse(entry).each{|descriptor, title|
            @rows[descriptor]['title'] ||= title
            @rows[descriptor]['entries'] << [entry['date'], entry['name']]
        }
    end
    
    def result
        rows = @rows.values.
                sort_by{|r| r['descriptor']}.
                map{|r| r.merge(
                    'entries' => r['entries'].sort_by(&:first).map(&:last),
                    'descriptor' => CGI.escape(r['descriptor'])
                    )
                }
        if grouped?
            {
                'meta' => {
                    'descriptor' => descriptor,
                    'title' => title,
                    'kind' => 'grouped'
                }, 
                'groups' => rows.group_ordered_by{|r| group_by(r['descriptor'])}.to_a.
                    map{|key, group| {'title' => key, 'rows' => group}}
            }
        
        else
            {
                'meta' => {
                    'descriptor' => descriptor,
                    'title' => title,
                    'kind' => 'plain'
                }, 
                'rows' => rows
            }
        end
    end
    
    def save(base_path)
        File.write(File.join(base_path, descriptor + '.js'), result.to_json)
    end
    
    private
    
    def parse(entry)
        [key(entry)].flatten.map{|key|
            [row_descriptor(key), row_title(key)]
        }
    end
    
    def key(entry); end
    def row_descriptor(key); key end
    def row_title(key); row_descriptor(key) end
    
    def grouped?; false end
end

class DateIndex < Index
    def descriptor; 'dates' end
    def title; 'Месяцы' end
    
    def key(entry); parse_time(entry['date']) end
    def row_descriptor(tm); tm.strftime('%Y-%m') end
    def row_title(tm); tm.strftime('%B') end
    
    def grouped?; true end
    def group_by(descriptor); descriptor.split('-', 2).first end
    #subindex 'days'
end


class HashtagIndex < Index
    def descriptor; 'hashtags' end
    def title; 'Теги' end
    
    def key(entry)
        extract_hashtags(entry['body']) + 
            (entry['comments'] || []).map{|c| extract_hashtags(c['body'])}.flatten
    end
end

#define_index 'days' do |under|
    #title under
    #extract{|entry| parse_time(entry['date'])}
    #descriptor{|v| v.strftime('%Y-%m-%d')}
    #friendly{|v| v.strftime('%d %B')}
#end

#define_list 'all' do
    #title 'Все'
    #reverse_sort_by{|entry| entry['date']}
#end

#define_list 'most_commented' do
    #title 'Топ по комментариям'
    #reverse_sort_by{|entry| entry['comments'].size}
#end

#define_list 'most_liked' do
    #title 'Топ по лайкам'
    #reverse_sort_by{|entry| entry['likes'].size}
#end
