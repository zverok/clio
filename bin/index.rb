$KCODE = 'u'

require 'pp'
require 'fileutils'
require 'cgi'

user = ARGV.shift
base_path = File.expand_path(File.join(File.dirname(__FILE__), '..'))
indexes_path = File.join(base_path, 'result', user, 'data', 'indexes')
entries_path = File.join(base_path, 'result', user, 'data', 'entries')
FileUtils.makedirs indexes_path

$:.unshift File.join(base_path, 'lib')
$:.unshift File.join(base_path, 'vendors')
require 'indexator'

INDEXES = [DateIndex, HashtagIndex, AllIndex]
indexes = INDEXES.map(&:new)

mode = ARGV.shift

unless mode == 'templates'
    # Index all entries
    Dir[File.join(entries_path, '*.js')].each do |f|
        text = File.read(f)
        name = f.sub(%r{.+/}, '')
        entry =  JSON.parse(text)
        indexes.each{|i| i.put(entry)}
    end

    indexes.each{|i| i.save(indexes_path)}
end

# Copy templates
templates_src = File.join(base_path, 'templates')
templates_dst = File.join(base_path, 'result', user)
Dir[File.join(templates_src, '**', '*.*')].each do |src|
    dst = src.sub(templates_src, templates_dst)
    FileUtils.makedirs(File.dirname(dst))
    FileUtils.cp src, dst
end

puts "Your archive is ready, see file://%s/index.html\n   ... or run `ruby bin/server.rb %s'" % [ templates_dst, user ]
