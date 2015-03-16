#!/usr/bin/env ruby
# encoding: utf-8

require 'pp'

$:.unshift File.expand_path('../../lib', __FILE__)

require 'slop'

require_relative '../lib/clio'


puts "Clio — better Friendfeed backup tool.  by zverok and contributors"
puts "=================================================================\n\n"

opts = Slop.parse(:help => true){
    on :u, :user=, "Ваш юзернейм"
    on :k, :key=, "Remote key для логина, берётся с http://friendfeed.com/remotekey"

    on :f, :feeds=,
        "Фид(ы) для загрузки, список через запятую: user1,group2,user3 (по умолчанию ваш собственный фид)",
        as: Array

    on :p, :path=,
        "Путь для сохранения фидов, по умолчанию папка result, каждый фид будет лежать в <path>/<feed>"

    on :l, :log=,
        "Путь для записи логов (по умолчанию STDOUT)"

    on :i, :indexonly,
        "Только проиндексировать (данные уже загружены)"
    on :noimages,
        "Не загружать картинки (по умолчанию будут загружены)"
    on :files,
        "Загружать вложенные файлы (музыку). По умолчанию НЕ БУДУТ загружены"

    on :depth=, "Глубина загрузки (количество новых записей); по умолчанию — максимально возможное"
    on :zip, "Упаковать в архив <path>/<feed>-<YYYY-MM-DD>.zip"

    on :d, :dates, "Флаг для добавления текущей даты в имя папки: <path>/<feed>/<YYYY-MM-DD> (для бакапов по расписанию)"
}

exit if opts.help?

trap("INT"){
    $stderr.puts "Прервано пользователем"
    exit(1)
}

begin
    clio = Clio.new(opts.to_hash)
    clio.run!
#rescue => e
    #logger.error "Вылетело по ошибке: #{e.message}"
end
