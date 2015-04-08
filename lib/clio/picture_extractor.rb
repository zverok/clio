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
                    @thumbnails << t.url if local?(t.url) &&
                        !t.url.include?('/old-') # это какой-то старинный артефакт, этих тумбнейлов нет уже
                    @images << t.link if local?(t.link)
                end
            end
        end
        log.info "Загружено: #{@thumbnails.count} адресов миниатюр, #{@images.count} адресов картинок"
    end

    def extract_thumbnails!
        context.path!('images/media/thumbnails/')
        
        thumbs = @thumbnails.reject{|url| thumb_exists?(url)}

        if thumbs.empty?
            log.info "Все миниатюры уже загружены"
        else
            log.info "Загружаем миниатюры: #{thumbs.count} из #{@thumbnails.count} ещё не было"

            thumbs.each_with_progress do |url|
                if response = get(url)
                    write_thumb(url, response)
                end
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
                if response = get(url)
                    if response.headers.key?(:content_disposition)
                        fname = response.headers[:content_disposition].to_s.force_encoding('UTF-8').scan(/filename="(.+)"/).flatten.first
                        !fname || fname.empty? and
                            fail("Что-то пошло не так при загрузке #{url}: #{response.headers}")

                        if fname.end_with?('.jpg.png') # ну спасибо блин ДОРОГОЙ ФРЕНДФИД!!!!
                            fname = fname.sub(/\.jpg\.png$/, '.jpg')
                        end

                        unless fname.include?('.')
                            fname += '.' + guess_ext(response)
                        end
                    else
                        ext = guess_ext(response)
                        fname = url.sub(/^.+\//, '') + ".#{ext}"
                    end

                    fname = context.sanitize_filename(fname)

                    while File.exists?(image_path(fname))
                        fname = context.next_name(fname)
                    end

                    write_image(image_path(fname), response.body)
                    imglog.puts [url, fname].join("\t")
                end
            end
        end
    end

    private

    def write_image(path, data)
        File.open(path, 'wb'){|f| f.write data.force_encoding('binary')}
    end

    def local?(url)
        url.include?('http://m.friendfeed-media.com/') ||
            url.include?('http://i.friendfeed.com/')
    end

    def thumb_path(url)
        context.path("images/media/thumbnails/#{url.sub(%r{.+/}, '')}.jpg")
    end

    def image_path(filename)
        context.path("images/media/#{filename}")
    end

    def get(url)
        RestClient.get(url)
    rescue RestClient::Forbidden
        nil
    rescue RestClient::Exception => e
        e.url = url
        raise
    end

    def write_thumb(url, response)
        base = url.sub(/^.+\//, '')
        ext = guess_ext(response)
        write_image(context.path("images/media/thumbnails/#{base}.#{ext}"), response.body)
    end

    def thumb_exists?(url)
        base = url.sub(/^.+\//, '')
        Dir[context.path("images/media/thumbnails/#{base}.*")].any?{|f| File.exists? f }
    end

    def guess_ext(response)
        case response.headers[:content_type]
        when /png/
            'png'
        when /jpeg/
            'jpg'
        when /gif/
            'gif'
        else
            'jpg'
        end
    end
end
