# encoding: utf-8
require 'frf_client'
require 'indexator'
require 'converter'
require 'userpic_loader'
require 'russian'
require 'cgi'

class Feed
    class << self
        attr_accessor :result_path
        attr_accessor :templates_path
    end

    Mash = Hashie::Mash

    def initialize(name)
        @name = name
        move_old_json!
    end

    attr_reader :name

    def load!(user, key)
    end

    def index!
    end

    def convert!
        Converter.new(self).run
    end

    def load_userpics!(user, key)
        UserpicLoader.new(self).run(user, key)
    end

    def result_path
        @result_path ||= File.join(self.class.result_path, name)
    end

    def templates_path
        self.class.templates_path
    end

    def path(*subpath)
        File.join(result_path, *subpath)
    end

    def path!(*subpath)
        path(*subpath).tap{|p| FileUtils.mkdir_p(File.dirname(p))}
    end

    def json_path(subpath)
        File.join(result_path, '_json/data', subpath)
    end

    def template_path(*subpath)
        File.join(templates_path, *subpath)
    end

    def haml_template(subpath)
        template_path('haml', subpath)
    end

    def haml(path)
        @templates ||= Hash.new{|h, path|
            h[path] = Haml::Engine.new(File.read(haml_template(path + '.haml')))
        }

        @templates[path]
    end

    def load_mash(path)
        Mash.new(JSON.parse(File.read(path)))
    end

    def make_filename(text)
        Russian.translit(CGI.unescape(text)).downcase.gsub(/[^-a-z0-9]/, '_')
    end

    def move_old_json!
        if File.exists?(path('data'))
            Clio.log.info "Найдены json-файлы старого архиватора, перемещаем"
            Clio.log.warn "Архивы в старом формате будут в подпапке _json"

            FileUtils.mkdir_p path('_json')
            %w[lib index.html entry.html list.html data images css].each do |f|
                FileUtils.mv(path(f), path('_json')) if File.exists?(path(f))
            end
        end
    end
end
