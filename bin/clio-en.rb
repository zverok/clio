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

opts = Slop.parse(:help => true){
    on :u, :user=, "Your username"
    on :k, :key=, "Your remote key from http://friendfeed.com/remotekey"
    on :f, :feeds=, "Feeds to load, comma-separated: user1,group2,user3 (your own feed by default)"
    on :p, :path=, "Path to store feeds, by default its `result`, with each feed at <path>/<feed>"
    on :l, :log=, "Path to write logs (STDOUT by default)"
    on :d, :dates, "If this flag provided, adds current date to folder name: <path>/<feed>/<YYYY-MM-DD> (useful for scheduled backups)"
    on :i, :indexonly, "Index only (data already loaded)"
    on :depth=, "Depth of download (how many new entries to download); maximum possible (~10'000) by default"
    on :zip, "Pack into archive <path>/<feed>-<YYYY-MM-DD>.zip"
}

exit if opts.help?

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
    $stderr.puts "\nERROR: Don't know what to load. Please use --feeds or --user options"
    exit(1)
end

unless opts[:indexonly] || (user && key)
    # we can't work without user+key
    puts opts
    $stderr.puts "\nERROR: You should provide both --user and --key (unless its --indexonly)"
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
    $stderr.puts "Interrupted by user"
    exit(1)
}

LANG = 'en'

begin
    feeds.each do |feed|
        path = File.join(result_path, feed)
        if opts.dates?
            path = File.join(path, Time.now.strftime('%Y-%m-%d'))
        end

        unless opts.indexonly?
            if client.extract(feed, path, :max_depth => opts[:depth].to_i, lang: 'en')
                puts "\n#{feed} loaded successfully, starting to index at #{path}\n\n"
            else
                $stderr.puts "\nLoading of #{feed} unsuccessful, please see logs"
                next
            end
        end

        Indexator.new(base_path, path, logger).run('en')
        puts "\n#{feed} indexed successfully, open file://#{path}/index.html"

        if opts.zip?
            require 'archive/zip'
            zip_path = File.join(result_path, "#{feed}-#{Time.now.strftime('%Y-%m-%d')}.zip")
            Archive::Zip.archive(zip_path, path)
            puts "\n#{feed} packed to #{zip_path}"
        end
    end
rescue => e
    logger.error "Interrupted by error: #{e.message}"
end
