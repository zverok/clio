# encoding: utf-8
class FileExtractor < Component
    def run
        load_urls!
        extract_files!
    end

    private

    def load_urls!
        log.info "Загружаем адреса вложений"
        @files = {}
        context.entries.each_with_progress do |e|
            if e.files
                e.files.select{|f| f.url.include?('m.friendfeed-media.com')}.each do |f|
                    name = sanitize_filename(f.name)
                    while @files.key?(name) && @files[name] != f.url
                        f.name = context.next_name(name)
                    end
                    @files[name] = f.url
                end
            end
        end
        File.write context.json_path('files.tsv'),
            @files.map{|name, url| [url, name].join("\t")}.join("\n")

        log.info "Загружено: #{@files.count} адресов файлов"
    end

    def extract_files!
        context.path!('files/')

        to_load = @files.reject{|name, url| File.exist?(context.path("files/#{name}"))}

        if to_load.empty?
            log.info "Все файлы уже загружены"
        else
            log.info "К загрузке #{to_load.count}"
            
            @files.each_with_progress do |name, url|
                File.open(context.path("files/#{name}"), 'wb'){|f| f.write RestClient.get(url).force_encoding('binary')}
            end
        end
    end

    def sanitize_filename(filename)
        filename.strip.
            gsub(/^.*(\\|\/)/, '').
            gsub(/[?!:]/, '_')
    end
end
