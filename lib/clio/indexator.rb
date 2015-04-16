# encoding: utf-8
require_relative './index'

class Indexator < Component
    INDEXES = [DateIndex, HashtagIndex, MediaIndex, LikesIndex, CommentsIndex, AllIndex]

    def run
        log.info "Начато #{description}"

        log.info "#{description}: индексируем"

        indexes = INDEXES.map(&:new)

        context.entries.each_with_progress do |e|
            indexes.each{|i| i.put(e)}
        end

        log.info "#{description}: записи прочитаны, сохраняем индексы"

        indexes.each{|i| i.save(context.json_path!('indexes/'))}

        log.info "#{description}: индексы сохранены, копируем шаблоны"

        # copy templates
        templates_src = context.templates_path
        templates_dst = context.path('_json')
        
        Dir[File.join(templates_src, '**', '*.*')].each do |src|
            next if src.include?('haml')
            
            dst = src.sub(templates_src, templates_dst)
            FileUtils.makedirs(File.dirname(dst))
            FileUtils.cp src, dst
        end

        log.info "#{description}: готово"
    end

    private

    def description
        "индексирование #{context.result_path}"
    end
end
