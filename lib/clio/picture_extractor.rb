# encoding: utf-8
class PictureExtractor < Component
    
    def run
        load_urls!
        extract_pictures!
    end

    def load_urls!
        log.info "Загружаем адреса картинок"
        @thumbnails = []
        @images = []

        context.entries.each_with_progress do |e|
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
        context.path!('images/media/')
        
        thumbs = @thumbnails.map{|url|
            [url, image_path(url)]
        }.reject{|u, path| File.exists?(path)}

        log.info "Загружаем миниатюры: #{thumbs.count} из #{@thumbnails.count} ещё не было"

        thumbs.each_with_progress do |url, path|
            File.write path, SimpleHttp.get(url)
        end

        imgs = @images.map{|url|
            [url, image_path(url)]
        }.reject{|u, path| File.exists?(path)}

        log.info "Загружаем картинки: #{imgs.count} из #{@images.count} ещё не было"
        imgs.each_with_progress do |url, path|
            File.write path, SimpleHttp.get(url)
        end
    end

    private

    # FIXME: всегда ли .png?
    def image_path(url)
        context.path("images/media/#{url.sub(%r{.+/}, '')}.png")
    end
end
