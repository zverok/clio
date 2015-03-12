# encoding: utf-8
class FeedLoader
    def initialize(feed)
        @feed = feed
    end

    attr_reader :feed

    PAGE_SIZE = 100

    def run(options = {})
        log.info "Загружаем метаинформацию #{feed.name}"

        File.write(feed.json_path!("feedinfo.js"), Clio.client.request("feedinfo/#{feed.name}"))
        
        log.info "Загружаем записи #{feed.name}"
        
        start = options.fetch(:start, 0)
        max = options.fetch(:max_depth, 0)
        
        prev_last_entry, last_entry = nil
    
        while next_page(start)
            start += PAGE_SIZE

            if !max.zero? && start > max
                log.info "Загружено заданное количество записей (#{max}). Останавливаемся."
                break
            end
        end
    end

    private

    def log
        Clio.log
    end

    def next_page(start)
        page = extract_feed(feed, start: start, num: PAGE_SIZE)
        
        if page['entries'].empty?
            log.info "Всё загружено, ура!"
            return false
        end
        
        entries = page['entries'].map{|e| process_entry(e)}
        feed.entries.push(*entries)

        if entries.last['date'] == @prev_oldest
            log.warn "Страница повторилась. Вероятно, наткнулись на ограничение FriendFeed. Останавливаемся."
            return false
        end

        entries.each do |e|
            File.write(feed.json_path!("entries/#{e['name']}.js"), e.to_json)
        end

        log.info "Загружено %i записей, начиная с %i; дата самой старой — '%s'" %
            [entries.size, start, entries.last['dateFriendly']]

        @prev_oldest = entries.last['date']
        true
    end
    
    def self.extract_feed(user, key, feedname, path, start = 0)
        frf = new(user, key)
        frf.extract(feedname, path, start)
    end

    private

    def extract_feed(name, params)
        Clio.client.request("feed/#{feed.name}", params)
    end

    def parse_time(str)
        str =~ /(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)Z/
        Time.local($1, $2, $3, $4, $5, $6)
    end
        
    def make_friendly_date(t)
        Russian.strftime(parse_time(t), '%d %B %Y в %H:%M')
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

