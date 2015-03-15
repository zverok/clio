# encoding: utf-8
class PictureExtractor < Component
    
    def run
        load_urls!
        extract_thumbnails!
        extract_images!
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

    def extract_thumbnails!
        context.path!('images/media/thumbnails/')
        
        thumbs = @thumbnails.map{|url|
            [url, thumb_path(url)]
        }.reject{|u, path| File.exists?(path)}

        if thumbs.empty?
            log.info "Все миниатюры уже загружены"
        else
            log.info "Загружаем миниатюры: #{thumbs.count} из #{@thumbnails.count} ещё не было"

            thumbs.each_with_progress do |url, path|
                File.write path, RestClient.get(url)
            end
        end
    end

    def extract_images!
        if File.exists?(context.json_path('images.tsv'))
            known = File.read(context.json_path('images.tsv')).split("\n").
                map{|ln| ln.split("\t")}.to_h
            imgs = @images.reject{|url| known.key?(url) && File.exists?(image_path(known[url]))}
        else
            imgs = @images.dup
        end

        if imgs.empty?
            log.info "Все картинки уже загружены"
        else
            imglog = File.open(context.json_path('images.tsv'), 'a')
            imglog.sync = true

            log.info "Загружаем картинки: #{imgs.count} из #{@images.count} ещё не было"

            imgs.each_with_progress do |url, path|
                response = RestClient.get(url)
                fname = response.headers[:content_disposition].scan(/filename="(.+)"/).flatten.first
                fname.empty? and
                    fail("Что-то пошло не так при загрузке #{url}: #{response.headers}")

                imglog.puts [url, fname].join("\t")
                
                File.write image_path(fname), response.body
            end
        end
    end

    private

    def thumb_path(url)
        context.path("images/media/thumbnails/#{url.sub(%r{.+/}, '')}.jpg")
    end

    def image_path(filename)
        context.path("images/media/#{filename}")
    end
end
