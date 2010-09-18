$KCODE = 'u'

require 'rubygems'
require 'pp'
require 'fileutils'
require 'cgi'

user = ARGV.first
base_path = File.expand_path(File.join(File.dirname(__FILE__), '..'))
indexes_path = File.join(base_path, 'result', user, 'data', 'indexes')
entries_path = File.join(base_path, 'result', user, 'data', 'entries')
FileUtils.makedirs indexes_path

$:.unshift File.join(base_path, 'lib')
$:.unshift File.join(base_path, 'vendors')
require 'indexator'

INDEXES = [DateIndex, HashtagIndex]
indexes = INDEXES.map(&:new)

Dir[File.join(entries_path, '*.js')].each do |f|
    text = File.read(f)
    name = f.sub(%r{.+/}, '')
    entry =  JSON.parse(text)
    indexes.each{|i| i.put(entry)}
end

indexes.each{|i| i.save(indexes_path)}
