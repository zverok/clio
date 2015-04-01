# encoding: utf-8
require 'russian'
require 'cgi'
require 'hashie'
require 'json'
require 'archive/zip'

require_relative './component'

require_relative './feed_extractor'
require_relative './search_feed_extractor'
require_relative './userpic_extractor'
require_relative './picture_extractor'
require_relative './file_extractor'

require_relative './indexator'
require_relative './converter'

Mash = Hashie::Mash

class FeedContext
    def initialize(clio, feed_name, options = {})
        @clio, @feed_name, @options = clio, feed_name, options

        move_old_json!
        
        @entries = []
    end

    attr_reader :clio, :feed_name, :entries, :options

    def search_request
        search_feed? or fail("Not a search feed: #{feed_name}")
        feed_name.sub(/^search=/, '')
    end

    def search_feed?
        feed_name =~ /^search=(.+)$/
    end

    # operations =======================================================
    def extract_feed!(max = 0)
        if search_feed?
            SearchFeedExtractor.new(self).run(max_depth: max)
        else
            FeedExtractor.new(self).run(max_depth: max)
        end
    end

    def extract_userpics!
        UserpicExtractor.new(self).run
    end

    def extract_pictures!
        PictureExtractor.new(self).run
    end

    def extract_files!
        FileExtractor.new(self).run
    end

    def index!
        Indexator.new(self).run
    end

    def convert!
        Converter.new(self).run
    end

    def zip!
        clio.log.info "Упаковываем результат"
        zip_path = File.join(clio.result_path, "#{folder_name}-#{Time.now.strftime('%Y-%m-%d')}.zip")
        Archive::Zip.archive(zip_path, result_path)
        clio.log.info "Результат упакован в #{zip_path}"
    end

    def reload_entries!
        @entries = []
        
        if Dir[json_path('entries/*.js')].empty?
            File.exists?(json_path('feedinfo.js')) or
                fail("Нет данных для этого фида (ищу в #{json_path('entries/*.js')}, забыли загрузить?..")

            log.warn "feedinfo.js есть, а записей нету, может быть не всё загрузили?"
            return
        end
            
        log.info "Загрузка всех записей #{feed_name}"
        Dir[json_path('entries/*.js')].
            reject{|fn| fn.sub(json_path('entries/'), '').include?('__')}.
            reject{|fn| File.basename(fn) == '46c998ba.js'}. # known buggy entry :)
            each_with_progress do |f|
                @entries << load_mash(f).merge(mtime: File.mtime(f))
            end
        
    end

    # pathes ===========================================================
    def result_path
        if options[:dates]
            @result_path ||= File.join(clio.result_path, folder_name, Time.now.strftime('%Y-%m-%d'))
        else
            @result_path ||= File.join(clio.result_path, folder_name)
        end
    end

    def templates_path
        clio.templates_path
    end

    def path_(*subpath)
        path(*subpath).sub(result_path + '/', '')
    end

    def path(*subpath)
        File.join(result_path, *subpath)
    end

    def path!(*subpath)
        path(*subpath).tap{|p| mkdir(p)}
    end

    def json_path(subpath)
        File.join(result_path, '_json/data', subpath)
    end

    def json_path!(subpath)
        json_path(*subpath).tap{|p| FileUtils.mkdir_p(File.dirname(p))}
    end

    def template_path(*subpath)
        File.join(templates_path, *subpath)
    end

    def haml_template_path(subpath)
        template_path('haml', subpath + '.haml')
    end

    def slim_template_path(subpath)
        template_path('slim', subpath + '.slim')
    end

    def make_filename(text)
        Russian.translit(CGI.unescape(text)).downcase.gsub(/[^-a-z0-9]/, '_')
    end

    def sanitize_filename(filename)
        # да WTF же вообще????
        # есть картинки с именами ".png" и т.п.
        if filename =~ /^\.(\w+)$/ 
            filename = "noname.#{$1}"
        end

        filename = filename.strip.
            gsub(/^.*(\\|\/)/, '')

        filename = Russian.translit(filename).
            gsub(/[^-a-zA-Z0-9._ ]/, '_').
            sub(/\.$/, '') # встретился файл «image.bmp.». чего только люди не выдумают!

        ensure_fname_length(filename)
    end

    MAXIMUM_FILENAME_LENGTH = 100

    def ensure_fname_length(fname)
        base, ext = fname.scan(/^(.+)\.(\w+)$/).flatten
        base.nil? and fail("Странное имя файла: #{fname}")
        if base.length > MAXIMUM_FILENAME_LENGTH
            base = base[0...MAXIMUM_FILENAME_LENGTH]
            "#{base}.#{ext}"
        else
            fname
        end
    end
    

    # name.png => name1.png, name12.png => name13.png
    def next_name(fn)
        fn.sub(/(\d*)\.(\w+)$/){|s| s.sub(/\d*/){|d| d.to_i + 1}}
    end

    # file services ====================================================
    def haml(path)
        @templates ||= Hash.new{|h, path|
            h[path] = Haml::Engine.new(File.read(haml_template_path(path)))
        }

        @templates[path]
    end

    def slim(path)
        @slim_templates ||= Hash.new{|h, path|
            h[path] = Slim::Template.new(slim_template_path(path), pretty: true)
        }

        @slim_templates[path]
    end

    def load_mash(path)
        Mash.new(JSON.parse(File.read(path)))
    end

    private

    def log
        clio.log
    end

    def mkdir(path)
        if path =~ %r{/$} # это путь к папке
            FileUtils.mkdir_p(path)
        else
            FileUtils.mkdir_p(File.dirname(path))
        end
    end

    def folder_name
        case feed_name
        when %r{^search=(.+)$}
            "#{clio.user}-#{Russian.translit(search_request.gsub(/[+\/:?*]/, '-'))}"
        when %r{^filter/(\w+)}
            "#{clio.user}-#{$1}"
        when %r{/}
            feed_name.gsub('/', '-')
        else
            feed_name
        end
    end

    def move_old_json!
        if File.exists?(path('data'))
            clio.log.info "Найдены json-файлы старого архиватора, перемещаем"
            clio.log.warn "Архивы в старом формате будут в подпапке _json"

            path!('_json')
            %w[lib index.html entry.html list.html data images css].each do |f|
                FileUtils.mv(path(f), path('_json')) if File.exists?(path(f))
            end
        end
    end
end
