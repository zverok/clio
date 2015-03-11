# encoding: utf-8
require 'haml'
require 'hashie'

require_relative './haml_partial'
require_relative './clio'

class Dumper
    Mash = Hashie::Mash
    
    def initialize(base_path, path, logger = nil)
        @base_path, @path = base_path, path
        @indexes_path = File.join(path, 'data', 'indexes')
        @entries_path = File.join(path, 'data', 'entries')
        @templates_path = File.join(base_path, 'templates', 'haml')
        Clio.haml_templates_path = @templates_path # FIXME very much!
        @html_path = File.join(path, 'html')

        @log = logger || SilenceLogger.new

        @layout = Haml::Engine.new(File.read("#{@templates_path}/layout.haml"))

        load_entries!
        load_sidebar_indexes!
        
    end

    attr_reader :log

    def run
        dump_entries

        #dump_indexes

        #dump_main
    end

    private

    def dump_entries
        html_entries_path = File.join(@html_path, 'entries')
        
        FileUtils.mkdir_p(html_entries_path)
        haml = Haml::Engine.new(File.read("#{@templates_path}/entry.haml"))

        log.info "Превращаем в HTML записи"
        
        @entries.first(5).each_with_progress do |name, entry|
            path = File.join(html_entries_path,"#{entry.name}.html")
            render_page(haml, path, entry)
        end
    end

    def render_page(template, path, data)
        helpers = Helpers.new(path.sub(@html_path + '/', ''))
        p helpers, helpers.relative('lists'), path.sub(@html_path, '')
        data = data.merge(sidebar_indexes: @sidebar_indexes)

        body = template.render(helpers, data)
        html = @layout.render(helpers, data){|region|
            region ? helpers[region] : body
        }

        File.write(path, html)
    end

    def dump_indexes
        haml = Haml::Engine.new(File.read("#{@templates_path}/list.haml"))
        
        Dir[File.join(@indexes_path, '*.js')].reject{|s| s =~ /all\.js$/}.sort.each do |f|
            index = Mash.new(JSON.parse(File.read(f)))
            rows = index.meta.kind == 'grouped' ? index.groups.map(&:rows).flatten : index.rows

            log.info "Превращаем в HTML списки по индексу: #{index.meta.title}"
            
            rows.each_with_progress do |row|
                path = File.join(@html_path, 'lists', index.meta.descriptor, row.descriptor + '.html')
                FileUtils.mkdir_p File.dirname(path)
                row.posts = row[:entries].map{|eid|
                        epath = File.join(@entries_path, "#{eid}.js")
                        Mash.new(JSON.parse(File.read(epath)))
                    }
                
                html = haml.render(row.merge(
                    sidebar_indexes: @sidebar_indexes,
                    index: index,
                    title: "#{index.meta.title}: #{row.title}"))
                File.write path, html
                    
            end
        end
    end

    PAGESIZE = 30

    def dump_main
        index = Mash.new(JSON.parse(File.read(File.join(@indexes_path, 'all.js'))))
        p index.rows.first[:entries].each_slice(PAGESIZE).count
    end

    def load_entries!
        @entries = {}
        log.info "Загружаем JSON для превращения в HTML"
        Dir[File.join(@entries_path, '*.js')].each_with_progress do |f|
            e = Mash.new(JSON.parse(File.read(f)))
            e.thumbnails ||= []
            e.via = nil unless e.key?(:via)
            @entries[e.name] = e
        end
    end

    def load_sidebar_indexes!
        @sidebar_indexes = []
        %w[dates hashtags].each do |iid|
            @sidebar_indexes << Mash.new(JSON.parse(File.read(File.join(@indexes_path, "#{iid}.js"))))
        end
    end
end
