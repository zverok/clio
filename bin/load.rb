#!/usr/bin/env ruby

require 'rubygems'
require 'pp'

base_path = File.expand_path(File.join(File.dirname(__FILE__), '..'))

$:.unshift File.join(base_path, 'lib')
$:.unshift File.join(base_path, 'vendors')

require 'core_ext'
require 'frf_client'

#user, key, * = *ARGV
user, start, * = *ARGV
start = start.to_i

puts File.join(base_path, 'result', user, 'data', 'entries')
#FriendFeedClient.extract_feed(user, nilkey, user, File.join(base_path, 'result', user, 'data', 'entries'), start)
FriendFeedClient.extract_feed(user, nil, user, File.join(base_path, 'result', user, 'data', 'entries'), start)
