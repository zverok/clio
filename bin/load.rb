#!/usr/bin/env ruby
$:.unshift 'lib'

require 'rubygems'
require 'pp'

require 'core_ext'
require 'frf_client'

base_path = File.expand_path(File.join(File.dirname(__FILE__), '..'))
user, key, * = *ARGV

FriendFeedClient.extract_feed(user, key, user, File.join(base_path, 'result', user, 'data', 'entries'))
