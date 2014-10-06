#!/usr/bin/env ruby
# encoding: utf-8
require 'ostruct'

dir = ARGV.first.dup
dir.sub!(%r{/$}, '')
puts "Проверяем файлы в #{dir}"

files = Dir["#{dir}/*.js"].sort.map{|f| 
   OpenStruct.new(canonical: f.sub(/__.*\.js/, '.js'), src: f, mtime: File.mtime(f))
}

files.group_by(&:canonical).each do |canonical, group|
    group = group.sort_by(&:mtime).reverse
    ops = []
    group[1..-1].each do |f|
        ops << "Переместить в архив: #{f.src}"
    end
    if group.first.src != canonical
        ops << "Скопировать в архив: #{group.first.src}"
        ops << "Переименовать #{group.first.src} => #{canonical}"
    end

    unless ops.empty?
        puts "Короткое имя: #{canonical}"
        puts "Требуемые операции: \n\t" + ops.join("\n\t")
    end
end
