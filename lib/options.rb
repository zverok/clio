module Options
  Options::VERSION = '2.3.2' unless defined?(Options::VERSION)

  class << Options
    def version
      Options::VERSION
    end

    def description
      'parse options from *args cleanly'
    end

    def normalize!(hash)
      hash.keys.each{|key| hash[key.to_s.to_sym] = hash.delete(key) unless Symbol===key}
      hash
    end
    alias_method 'to_options!', 'normalize!'

    def normalize(hash)
      normalize!(hash.dup)
    end
    alias_method 'to_options', 'normalize'

    def stringify!(hash)
      hash.keys.each{|key| hash[key.to_s] = hash.delete(key) unless String===key}
      hash
    end
    alias_method 'stringified!', 'stringify!'

    def stringify(hash)
      stringify!(hash)
    end
    alias_method 'stringified', 'stringify'

    def for(hash)
      hash =
        case hash
          when Hash
            hash
          when Array
            Hash[*hash.flatten]
          when String, Symbol
            {hash => true}
          else
            hash.to_hash
        end
      normalize!(hash)
    ensure
      hash.extend(Options) unless hash.is_a?(Options)
    end

    def parse(args)
      case args
      when Array
        args.extend(Arguments) unless args.is_a?(Arguments)
        [args, args.options.pop]
      when Hash
        Options.for(args)
      else
        raise ArgumentError, "`args` should be an Array or Hash"
      end
    end
  end

  def to_options!
    replace to_options
  end

  def to_options
    keys.inject(Hash.new){|h,k| h.update k.to_s.to_sym => fetch(k)}
  end
        
  def getopt key, default = nil
    [ key ].flatten.each do |key|
      return fetch(key) if has_key?(key)
      key = key.to_s
      return fetch(key) if has_key?(key)
      key = key.to_sym
      return fetch(key) if has_key?(key)
    end
    default
  end

  def getopts *args
    args.flatten.map{|arg| getopt arg}
  end

  def hasopt key, default = nil
    [ key ].flatten.each do |key|
      return true if has_key?(key)
      key = key.to_s
      return true if has_key?(key)
      key = key.to_sym
      return true if has_key?(key)
    end
    default
  end
  alias_method 'hasopt?', 'hasopt'

  def hasopts *args
    args.flatten.map{|arg| hasopt arg}
  end
  alias_method 'hasopts?', 'hasopts'

  def delopt key, default = nil
    [ key ].flatten.each do |key|
      return delete(key) if has_key?(key)
      key = key.to_s
      return delete(key) if has_key?(key)
      key = key.to_sym
      return delete(key) if has_key?(key)
    end
    default
  end

  def delopts *args
    args.flatten.map{|arg| delopt arg}
  end

  def setopt key, value = nil
    [ key ].flatten.each do |key|
      return self[key]=value if has_key?(key)
      key = key.to_s
      return self[key]=value if has_key?(key)
      key = key.to_sym
      return self[key]=value if has_key?(key)
    end
    return self[key]=value
  end
  alias_method 'setopt!', 'setopt'

  def setopts opts 
    opts.each{|key, value| setopt key, value}
    opts
  end
  alias_method 'setopts!', 'setopts'

  def select! *a, &b
    replace select(*a, &b).to_hash
  end

  def normalize!
    Options.normalize!(self)
  end
  alias_method 'normalized!', 'normalize!'
  alias_method 'to_options!', 'normalize!'

  def normalize
    Options.normalize(self)
  end
  alias_method 'normalized', 'normalize'
  alias_method 'to_options', 'normalize'

  def stringify!
    Options.stringify!(self)
  end
  alias_method 'stringified!', 'stringify!'

  def stringify
    Options.stringify(self)
  end
  alias_method 'stringified', 'stringify'

  attr_accessor :arguments
  def pop
    pop! unless popped?
    self
  end

  def popped?
    defined?(@popped) and @popped
  end

  def pop!
    if arguments.last.is_a?(Hash)
      @popped = arguments.pop
    else
      @popped = true
    end
  end

  # Validates that the options provided are acceptable.
  #
  # @param [Symbol] *acceptable_options List of options that are
  #   allowed
  def validate(*acceptable_options)
    remaining = (provided_options - acceptable_options).map{|opt| opt.to_s}.sort
    raise ArgumentError, "Unrecognized options: #{remaining.join(', ')}" unless remaining.empty?
    
    self
  end

  protected

  def provided_options
    normalize!.keys
  end
end

module Arguments
  def options
    @options ||= Options.for(last.is_a?(Hash) ? last : {})
  ensure
    @options.arguments = self
  end

  class << Arguments
    def for(args)
      args.extend(Arguments) unless args.is_a?(Arguments)
      args
    end

    def parse(args)
      [args, Options.parse(args)]
    end
  end
end

class Array
  def options
    extend(Arguments) unless is_a?(Arguments)
    options
  end
end
