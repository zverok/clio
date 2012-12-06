#!/usr/bin/env ruby

require 'webrick'
include WEBrick

require 'fileutils'


puts "Clio Server.  by zverok and contributors"
puts "=========================================\n\n"

if ARGV.length < 1
    $stderr.puts "Usage: server.rb feedname"
    exit(1)
end

port = 0xfeed
base_path = File.expand_path(File.join(File.dirname(__FILE__), '..'))

feed = ARGV.shift
document_root = File.join(base_path, 'result', feed)

unless File.exists? "%s/index.html" % document_root
    $stderr.puts "Can't find archive of %s feed" % feed
    exit(1)
end

server = HTTPServer.new({
    :Port            => port,
    :Logger          => Log.new($stderr, Log::FATAL),
    :AccessLog       => [[
        File.open(RUBY_PLATFORM =~ /mswin/ ? 'NUL:' : '/dev/null', 'w'),
        AccessLog::COMBINED_LOG_FORMAT
    ]],
    :DocumentRoot    => document_root,
})

# trap signals to invoke the shutdown procedure cleanly
['INT', 'TERM'].each { |signal|
    trap(signal){ server.shutdown} 
}

puts "Serving FriendFeed archive of %s on http://localhost:%d/index.html" % [feed, port]

server.start
