#!/usr/bin/env ruby

require 'pp'
require 'logger'

base_path = File.expand_path(File.join(File.dirname(__FILE__), '..'))

$:.unshift File.join(base_path, 'lib')
$:.unshift File.join(base_path, 'vendors')

require 'slop'

require 'core_ext'
require 'log_utils'
require 'frf_client'
require 'indexator'

user, key, feed, * = *ARGV
feed ||= user

opts = Slop.parse(:help => true){
    on :u, :user=, "Ваш юзернейм"
    on :k, :key=, "Remote key для логина, берётся с http://friendfeed.com/remotekey"
    on :f, :feeds=, "Фид(ы) для загрузки, список через запятую (по умолчанию ваш собственный фид)"
    on :p, :path=, "Путь для сохранения фидов, по умолчанию папка result, каждый фид будет лежать в <path>/<feed>"
    on :l, :log=, "Путь для записи логов (по умолчанию STDOUT)"
    on :d, :dates, "Флаг для добавления текущей даты в имя папки: <path>/<feed>/<YYYY-MM-DD> (для бакапов по расписанию)"
    on :i, :indexonly, "Только проиндексировать (данные уже загружены)"
}

unless opts[:user] || opts[:feed]
    exit(0)
end

feeds = (opts[:feeds] || user).split(/\s*,\s*/)

logger = Logger.new(opts[:log] ? opts[:log] : STDOUT).tap{|l|
    l.formatter = PrettyFormatter.new
}

unless opts.indexonly?
    client = FriendFeedClient.new(opts[:user], opts[:key], logger)
end

result_path = opts[:path] || File.join(base_path, 'result')

trap("INT"){
    puts "Прервано пользователем"
    exit(1)
}

feeds.each do |feed|
    path = File.join(result_path, feed)
    if opts.dates?
        path = File.join(path, Time.now.strftime('%Y-%m-%d'))
    end

    if opts.indexonly?
        Indexator.new(base_path, path, logger).run
    else
        if client.extract(feed, path)
            puts "\n#{feed} загружен, запускаем индексатор #{path}\n\n"
            Indexator.new(base_path, path, logger).run
            puts "\n#{feed} загружен и проиндексирован, см. file://#{path}/index.html"
        else
            puts "\nЗагрузка #{feed} не удалась, смотрите логи"
        end
    end
end
