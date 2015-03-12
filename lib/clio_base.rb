# encoding: utf-8
require 'logger'
require 'log_utils'

module Clio
    class << self
        attr_accessor :haml_templates_path

        attr_accessor :options

        attr_accessor :client

        def log
            @log ||= Logger.new(options[:log] ? options[:log] : STDOUT).tap{|l|
                l.formatter = PrettyFormatter.new
            }
        end
    end
end
