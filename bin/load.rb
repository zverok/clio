#!/usr/bin/env ruby

require 'pp'

base_path = File.expand_path(File.join(File.dirname(__FILE__), '..'))

$:.unshift File.join(base_path, 'lib')
$:.unshift File.join(base_path, 'vendors')

require 'core_ext'
require 'frf_client'

user, key, * = *ARGV

FriendFeedClient.extract_feed(user, key, user, File.join(base_path, 'result', user))

puts "Data is loaded, remember to run `ruby bin/index.rb %s' to create HTML pages" % user
