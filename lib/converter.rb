# encoding: utf-8
require 'haml'
require 'hashie'

require_relative './haml_helpers'

class Converter
    Mash = Hashie::Mash
    PAGE_SIZE = 30

    def initialize(feed)
        @feed = feed
        @entries = {}
        
        #@base_path, @path = base_path, path
        #@indexes_path = File.join(path, 'data', 'indexes')
        #@entries_path = File.join(path, 'data', 'entries')
        #@templates_path = File.join(base_path, 'templates', 'haml')
        #Clio.haml_templates_path = @templates_path # FIXME very much!
        #@html_path = File.join(path, 'html')

        #@log = logger || SilenceLogger.new

        #@layout = Haml::Engine.new(File.read("#{@templates_path}/layout.haml"))

        load_entries!
        load_sidebar_indexes!
        
    end

    attr_reader :feed, :entries

    def run
        copy_static

        dump_entries

        dump_indexes

        dump_main
    end

    private

    def log
        Clio.log
    end

    def copy_static
        %w[css js images].each do |f|
            FileUtils.cp_r feed.template_path("haml/#{f}"), feed.result_path
        end
    end

    def dump_entries
        log.info "Превращаем в HTML записи"

        @entries.each_with_progress do |name, entry|
            render_page('entry', "entries/#{entry.name}.html", entry)
        end
    end

    def dump_indexes
        Dir[feed.json_path('indexes/*.js')].reject{|s| s =~ /(days__.+|all)\.js$/}.sort.each do |f|
            index = load_mash(f)
            rows = index.meta.kind == 'grouped' ? index.groups.map(&:rows).flatten : index.rows

            log.info "Превращаем в HTML списки по индексу: #{index.meta.title}"
            
            rows.each_with_progress do |row|
                # метод entries у Hashie::Mash занят, поэтому приходится доступ по символу
                # и переобозовать в posts
                row.posts = entries.values_at(*row[:entries])

                render_page(
                    'list',
                    "lists/#{index.meta.descriptor}/#{feed.make_filename(row.descriptor)}.html",
                    row.merge(
                        index: index,
                        title: "#{index.meta.title}: #{row.title}"
                    )
                )
            end
        end
    end

    def dump_main
        log.info "Строим основную страницу фида"

        total = (@entries.count / PAGE_SIZE).ceil
        pages = (0..total).map{|i|
            i.zero? ? "" : "#{i*PAGE_SIZE}-#{(i+1)*PAGE_SIZE-1}"
        }

        entries.values.sort_by(&:date).reverse.
            each_slice(PAGE_SIZE).zip(pages).each_with_index.to_a.
            each_with_progress do |(entries, page), i|

            render_page(
                'index',
                "index#{page}.html",
                entries: entries, pager: {cur: i, pages: pages}
            )
        end
    end

    def render_page(template_path, path, data)
        helpers = Helpers.new(feed, path)
        data = Mash.new(data).merge(sidebar_indexes: @sidebar_indexes)

        body = feed.haml(template_path).render(helpers, data)
        html = feed.haml('layout').render(helpers, data){|region|
            region ? helpers[region] : body
        }

        File.write(feed.path!(path), html)
    end


    def load_entries!
        log.info "Загружаем JSON для превращения в HTML"

        Dir[feed.json_path('entries/*.js')].each_with_progress do |f|
            e = load_mash(f)
            e.thumbnails ||= []
            e.via = nil unless e.key?(:via)
            e.to = nil unless e.key?(:to)
            e.title = e.body.gsub(/<.+?>/, '')
            @entries[e.name] = e
        end
    end

    def load_sidebar_indexes!
        @sidebar_indexes = %w[dates hashtags].map{|iid|
            load_mash(feed.json_path("indexes/#{iid}.js"))
        }
    end

    def load_mash(path)
        Mash.new(JSON.parse(File.read(path)))
    end
end
