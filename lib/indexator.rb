require 'json'
require 'core_ext'

require 'rutils/datetime/datetime'

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
        @subindexes = Hash.new{|h,k| h[k] = subindex.new(k)}
    end
    
    def put(entry)
        parse(entry).each do |descriptor, title|
            @rows[descriptor]['title'] ||= title
            @rows[descriptor]['entries'] << [entry['date'], entry['name']]
            
            if has_subindexes?
                @subindexes[descriptor].put(entry) 
                @rows[descriptor]['subindex'] ||= @subindexes[descriptor].descriptor
            end
        end
    end
    
    def result
        rows = @rows.values.
                sort_by{|r| r['descriptor']}.
                map{|r| r.merge(
                    'entries' => r['entries'].sort_by(&:first).reverse.map(&:last),
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
        @subindexes.values.each{|si| si.save(base_path)}
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
    def has_subindexes?; not subindex.nil? end
    def subindex; nil end
end

class DateIndex < Index
    def descriptor; 'dates' end
    def title; 'Месяцы' end
    
    def key(entry); parse_time(entry['date']) end
    def row_descriptor(tm); tm.strftime('%Y-%m') end
    def row_title(tm); tm.strftime('%B') end
    
    def grouped?; true end
    def group_by(descriptor); descriptor.split('-', 2).first end
    
    def subindex; MonthDaysIndex end
end


class HashtagIndex < Index
    def descriptor; 'hashtags' end
    def title; 'Теги' end
    
    def key(entry)
        extract_hashtags(entry['body']) + 
            (entry['comments'] || []).map{|c| extract_hashtags(c['body'])}.flatten
    end
end

class MonthDaysIndex < Index
    def initialize(month_descriptor)
        super()
        @month = Time.local(*(month_descriptor + '-01').split('-'))
    end
    
    def descriptor; "days__#{@month.strftime('%Y-%m')}" end
    def title; @month.strftime('%B %Y') end
    
    def key(entry); parse_time(entry['date']) end
    def row_descriptor(tm); tm.strftime('%d') end
end

class AllIndex < Index
    def descriptor; 'all' end
    def title; 'Все' end
    
    def key(entry)
        'all'
    end
end

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
