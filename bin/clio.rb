#!/usr/bin/env ruby
# encoding: utf-8

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


puts "Clio — better Friendfeed backup tool.  by zverok and contributors"
puts "=================================================================\n\n"

user, key, feed, * = *ARGV

opts = Slop.parse(:help => true){
    on :u, :user=, "Ваш юзернейм"
    on :k, :key=, "Remote key для логина, берётся с http://friendfeed.com/remotekey"
    on :f, :feeds=, "Фид(ы) для загрузки, список через запятую: user1,group2,user3 (по умолчанию ваш собственный фид)"
    on :p, :path=, "Путь для сохранения фидов, по умолчанию папка result, каждый фид будет лежать в <path>/<feed>"
    on :l, :log=, "Путь для записи логов (по умолчанию STDOUT)"
    on :d, :dates, "Флаг для добавления текущей даты в имя папки: <path>/<feed>/<YYYY-MM-DD> (для бакапов по расписанию)"
    on :i, :indexonly, "Только проиндексировать (данные уже загружены)"
}

if opts[:user]
    user = opts[:user]
end

if opts[:key]
    key = opts[:key]
end

if opts[:feeds]
    feeds = opts[:feeds]
end

if user && user[0,1] == "-"
    # if "user" starts with "-" that's probably option-parsing artifact and we should ignore it
    user = nil
end

unless feeds
    feeds = user
end

unless feeds
    puts opts
    $stderr.puts "\nERROR: Непонятно что скачивать. Укажите параметр --feeds или --user"
    exit(1)
end

unless opts[:indexonly] || (user && key)
    # we can't work without user+key
    puts opts
    $stderr.puts "\nERROR: Необходимо указать либо опции --user и --key, либо --indexonly"
    exit(1)
end

feeds = feeds.split(/\s*,\s*/)

logger = Logger.new(opts[:log] ? opts[:log] : STDOUT).tap{|l|
    l.formatter = PrettyFormatter.new
}

unless opts.indexonly?
    client = FriendFeedClient.new(user, key, logger)
end

result_path = opts[:path] || File.join(base_path, 'result')

trap("INT"){
    $stderr.puts "Прервано пользователем"
    exit(1)
}

feeds.each do |feed|
    path = File.join(result_path, feed)
    if opts.dates?
        path = File.join(path, Time.now.strftime('%Y-%m-%d'))
    end

    unless opts.indexonly?
        if client.extract(feed, path)
            puts "\n#{feed} загружен, запускаем индексатор #{path}\n\n"
        else
            $stderr.puts "\nЗагрузка #{feed} не удалась, смотрите логи"
            next
        end
    end

    Indexator.new(base_path, path, logger).run
    puts "\n#{feed} проиндексирован, см. file://#{path}/index.html"
end
