# encoding: utf-8
class PictureLoader
    def initialize(feed)
        @feed = feed
    end

    attr_reader :feed
    
    def run
        load_urls!
        extract_pictures!
    end

    def load_urls!
        log.info "Загружаем адреса картинок"
        @thumbnails = []
        @images = []

        Dir[feed.json_path('entries/*.js')].each_with_progress do |f|
            e = feed.load_mash(f)
            if e.thumbnails
                e.thumbnails.each do |t|
                    @thumbnails << t.url if t.url.include?('http://m.friendfeed-media.com/')
                    @images << t.link if t.link.include?('http://m.friendfeed-media.com/')
                end
            end
        end
        log.info "Загружено: #{@thumbnails.count} адресов миниатюр, #{@images.count} адресов картинок"
    end

    def extract_pictures!
        log.info "Загружаем миниатюры"
        @thumbnails.each_with_progress do |url|
            name = url.sub(%r{.+/}, '') + '.png' # FIXME: всегда ли?
            path = feed.path!("images/media/#{name}")
            unless File.exists?(path)
                File.write path, SimpleHttp.get(url)
            end
        end

        log.info "Загружаем картинки"
        @images.each_with_progress do |url|
            name = url.sub(%r{.+/}, '') + '.png' # FIXME: всегда ли?
            path = feed.path!("images/media/#{name}")
            unless File.exists?(path)
                File.write path, SimpleHttp.get(url)
            end
        end
    end

    private

    def log
        Clio.log
    end
    
end
