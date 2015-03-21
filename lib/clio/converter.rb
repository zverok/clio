# encoding: utf-8
require 'haml'

require_relative './haml_helpers'

class Converter < Component
    PAGE_SIZE = 30

    attr_reader :entries, :likes

    def run
        load_entries!
        load_sidebar_indexes!

        copy_static

        dump_entries

        dump_indexes

        dump_main

        dump_feedinfo
    end

    private

    def copy_static
        %w[css js images].each do |f|
            FileUtils.cp_r context.template_path("haml/#{f}"), context.result_path
        end
    end

    def dump_entries
        log.info "Превращаем в HTML записи"

        @entries.each_with_progress do |name, entry|
            render_page('entry', "entries/#{entry.name}.html", entry)
        end

        log.info "Превращаем в HTML залайканные записи"

        @likes.each_with_progress do |name, entry|
            render_page('entry', "likes/#{entry.name}.html", entry)
        end
    end

    def dump_indexes
        # индексы по дням в HTML не превращаем. баловство это!
        Dir[context.json_path('indexes/*.js')].reject{|s| s =~ /(days__.+|all)\.js$/}.sort.each do |f|
            index = context.load_mash(f)
            rows = index.meta.kind == 'grouped' ? index.groups.map(&:rows).flatten(1) : index.rows

            log.info "Превращаем в HTML списки по индексу: #{index.meta.title}"

            rows.each_with_progress do |row|
                if index.meta.descriptor != 'likes'
                    # метод entries у Hashie::Mash занят, поэтому приходится доступ по символу
                    # и переобозовать в posts
                    row.posts = entries.values_at(*row[:entries])
                else
                    # лайки нельзя добавлять в entries, потому что тогда они попадают в общую ленту,
                    # так что подменяем row.posts, чтобы дальше ничего не менять
                    row.posts = likes.values_at(*row[:entries])
                end

                render_page(
                    'list',
                    "lists/#{index.meta.descriptor}/#{context.make_filename(row.descriptor)}.html",
                    row.merge(
                        index: index,
                        title: "#{index.meta.title}: #{row.title}",
                        mtime: row.posts.map(&:mtime).max
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

            path = i > 0 ? "pages/index#{page}.html" : 'index.html'
            render_page(
                'index',
                path,
                entries: entries,
                pager: {cur: i, pages: pages},
                mtime: entries.map(&:mtime).max
            )
        end
    end

    def dump_feedinfo
        log.info "Строим страницу профайла"
        render_page('info', 'info.html', {}) # feedinfo и так передаётся
    end

    def newer?(path, tm)
        path = context.path(path)
        File.exists?(path) && File.mtime(path) > tm
    end

    def render_page(template_path, path, data)
        return if data[:mtime] && newer?(path, data[:mtime])

        helpers = Helpers.new(context, path)
        data = Mash.new(data).merge(
            sidebar_indexes: @sidebar_indexes,
            info: feedinfo
        )

        body = context.haml(template_path).render(helpers, data)
        html = context.haml('layout').render(helpers, data){|region|
            region ? helpers[region] : body
        }

        File.write(context.path!(path), html)
    end

    def feedinfo
        if @feedinfo
            return @feedinfo
        end

        @feedinfo ||= context.load_mash(context.json_path('feedinfo.js'))
        @feedinfo['likes'] = @likes
        return @feedinfo
    end

    def load_entries!
        @entries = {}
        @likes = {}

        log.info "Подготавливаем JSON к превращению в HTML"

        context.entries.each_with_progress do |e|
            e.thumbnails ||= []
            e.files ||= []
            e.via = nil unless e.key?(:via)
            e.to = nil unless e.key?(:to)
            e.title = e.body.gsub(/<.+?>/, '')
            @entries[e.name] = e
        end

        context.likes.each_with_progress do |e|
            e.thumbnails ||= []
            e.files ||= []
            e.via = nil unless e.key?(:via)
            e.to = nil unless e.key?(:to)
            e.title = e.body.gsub(/<.+?>/, '')
            @likes[e.name] = e
        end
    end

    def load_sidebar_indexes!
        @sidebar_indexes = %w[dates hashtags].map{|iid|
            context.load_mash(context.json_path("indexes/#{iid}.js"))
        }
    end
end
