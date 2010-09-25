$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))


require 'net/http'
require 'net/https'
require 'uri'
require 'cgi'
require 'base64'


# Wrapper around ruby's standard net/http classes. Currently, only GET
# and POST https methods are supported. `SimpleHttp` provides class
# methods `get` and `post` to handle basic functionality. In case more
# complicated requests need to be made or default settings need to be
# overriden, it's possible to instantiate `SimpleHttp` and use instance
# methods `get` and `put`.
#  
#
# Features:
# 
# * Handles Redirects automatically
# * Proxy used transparently if http_proxy environment variable is
#   set.
# * SSL handled automatically
# * fault tolerant uri, e.g. all of these would work:
# 	"www.example.com", "www.example.com/", "http://www.example.com"
#
# Some usage examples:
#		# plain GET (using class methods)
#		SimpleHttp.get "www.example.com"
#
#		# POST using the instance methods
#		uri = URI.parse "https://www.example.com/index.html"
#		sh = SimpleHttp uri
#		sh.set_proxy "my.proxy", "8080"
#		sh.post {"query" => "query_data"}
#
#		# POST using class methods.
#		binaryData = getImage
#		SimpleData.post binaryData, "image/png"
#
#		# GET requst with a custom request_header
#		sh = SimpleHttp.new "http://www.example.com"
#		sh.request_headers= {'X-Special-Http-Header'=>'my-value'}
#		sh.get
class SimpleHttp
	
	VERSION='0.1.3'

	attr_accessor :proxy_host, :proxy_port, :proxy_user, :proxy_pwd, :uri, :request_headers, :response_headers, :response_handlers, :follow_num_redirects
	RESPONSE_HANDLERS = {
		Net::HTTPResponse => lambda { |request, response, http| 
			response.each_header {|key, value|
				http.response_headers[key]=value	
			}
			raise "#{response.to_s} : #{response.code} : #{http.uri}"
		},
		Net::HTTPSuccess => lambda { |request, response, http|
			response.each_header {|key, value|
				http.response_headers[key]=value	
			}
			#http.cookies += response.cookies
			if request.class == Net::HTTP::Head || request.class == Net::HTTP::Options
				return http.response_headers 
			end
			return response.body
		},
		Net::HTTPRedirection =>  lambda { |request, response, http|
			raise "too many redirects!" unless http.follow_num_redirects > 0	
			# create a new SimpleHttp for the location
			# refered to decreasing the remaining redirects
			# by one.
			
			if (location = response['location']) !~ /^https?:\/\//
				new_location = "#{http.uri.scheme}://#{http.uri.host}"
				if location =~ /^\//
					new_location += location
				else
					new_location += "/#{http.uri.path}/#{location}"
				end
				location = new_location	
			end

			sh = SimpleHttp.new location 
			#STDERR.puts location	
			sh.follow_num_redirects = http.follow_num_redirects-1

			# copy the response handlers used in the current
			# request in case they were non standard.
			sh.response_handlers = http.response_handlers

			# copy the request headers
			sh.request_headers=http.request_headers
			sh.response_headers=http.response_headers
			#sh.cookies+=http.cookies

			# copy host and port
			sh.uri.host = http.uri.host
			sh.uri.port = http.uri.port

			# HTTP doesn't permit redirects for methods other than
			# GET or HEAD. The exception is 303 redirects, which
			# should automatically follow the redirect URI using a
			# GET method regardless of the initial method. For
			# other classes of redirection, the client is required
			# to prompt the user before redirection occurs. Because
			# that's not a feasible action for this library, all
			# 3xx redirect URIs are followed using a GET method. 
			#
			# http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html

			case request
			when 	Net::HTTP::Get, 
				Net::HTTP::Head,
				Net::HTTP::Options
				
				sh.get
			when Net::HTTP::Post
				sh.request_headers['content-length']=nil
				sh.get
 			else 
 				raise "Not a valid HTTP method for redirection: #{request.class}"
			end

		}

	}

	# SimpleHttp can either be used directly through the +get+ and
	# +post+ class methods or be instantiated, in case you need to
	# to add custom behaviour to the requests.
	#
	# @param may be a URI or a String.
	#
	# Example:
	# 	http = SimpleHttp.new(URI.parse("http://www.example.com"))
	# 	http = SimpleHttp.new "www.example.com"
	# 	http = SimpleHttp.new "http://usr:pwd@www.example.com:1234"
	def initialize uri
		set_proxy ENV['http_proxy'] if ENV['http_proxy']
						
		if uri.class == String

			unless uri =~ /^https?:\/\//
				uri = "http://#{uri}"
			end

			uri = URI.parse uri

		end
		@uri = uri
		if !@uri.path || "" == @uri.path.strip
			@uri.path="/"
		end


		@request_headers={}
		@response_headers={}
		@cookies=[]
		@response_handlers=RESPONSE_HANDLERS.clone
		@follow_num_redirects=5

		if @uri.user
			basic_authentication @uri.user, @uri.password
		end

	end

	# 
	# Provides facilities to perform http basic authentication. You
	# don't need to provide +usr+ and +pwd+ if they are already included
	# in the uri, i.e. http://user:password@www.example.com/
	#
	
	def basic_authentication usr, pwd
		str = Base64.encode64("#{usr}:#{pwd}")
		str = "Basic #{str}"
		@request_headers["Authorization"]=str
	end
	
	#
	# this method can be used to register response handlers for specific
	# http responses in case you need to override the default behaviour.
	# Defaults are: 
	#
	# 	HTTPSuccess : return the body of the response 
	# 	HTTPRedirection : follow the redirection until success
	# 	Others : raise an exception 
	#
	# `clazz` is the subclass of HTTPResponse (or HTTPResponse in case you
	# want to define "default" behaviour) that you are registering the
	# handler for.
	#
	# `block` is the handler itself, if a response of the appropriate class
	# is received, `block` is called with three parameters: the the
	# Net::HTTPRequest, the actual HTTPResponse object that was received
	# and a reference to the instance of `SimpleHttp` that is executing the
	# call.
	#
	# example: 
	#
	# 	# to override the default action of following a HTTP
	# 	# redirect, you could register the folllowing handler:
	#
	# 	sh = SimpleHttp "www.example.com" 
	# 	sh.register_response_handler Net::HTTPRedirection {|request, response, shttp| 
	# 		response['location'] 
	# 	}
	#
	
	def register_response_handler clazz, &block
		c = clazz
	       	while c != Object
			# completely unnecessary sanity check to make sure parameter
			# `clazz` is in fact a HTTPResponse ...
			if c == Net::HTTPResponse
				@response_handlers[clazz]=block 
				return
			end
			c = c.superclass
		end

		raise "Trying to register a response handler for non-response class: #{clazz}"	
	end

	#
	#	Set the proxy to use for the http request.
	# 	Note that you don't need to set the proxy in case the
	# 	`http_proxy` environment variable is set. To override 
	#	previous proxy settings and connect directly, call 
	#	`set_proxy nil`
	#
	#	usage:
	#		http = SimpleHttp.new "www.example.com"
	#		
	#		http.set_proxy "http://proxy:8000"
	#	or:
	#		http.set_proxy(URI.parse("http://proxy:8000"))
	#	or:
	#		http.set_proxy 'proxy', '8000', 'my_user', 'secret'
	#	or:
	#		http.set_proxy nil # to override previous proxy
	#		settings and make the request directly.
	#
			
	
	def set_proxy proxy, port=nil, user=nil, pwd=nil
		
		
		if !proxy	
			@proxy_host=@proxy_port=@proxy_user=@proxy_pwd=nil 
			return
		end

		if proxy.class == String 
			if !port && !user && !pwd
				proxy = URI.parse(proxy)
			else 
				@proxy_host= host
				@proxy_port= port
				@proxy_user= user
				@proxy_pwd = pwd
			end
		end
		
		if proxy.class == URI::HTTP 
			@proxy_host= proxy.host
			@proxy_port= proxy.port
			@proxy_user= proxy.user
			@proxy_pwd = proxy.password
		end
	end

	# interal 
	# Takes a HTTPResponse (or subclass) and determines how to
	# handle the response. Default behaviour is:
	#
	# 	HTTPSuccess : return the body of the response
	# 	HTTPRedirection : follow the redirect until success.
	# 	default : raise the HTTPResponse.
	#
	# the default behaviour can be overidden by registering a
	# response handler using the `register_response_handler` method.
	#
	
	def handle_response http_request, http_response
		raise "Not a Net::HTTPResponse" unless http_response.is_a? Net::HTTPResponse
		
		c = http_response.class
		while c!=Object
			# the response_handlers hash contains a handler
			# for the specific response class.
			if @response_handlers[c]
			#STDERR.puts "!#{http_response.class}"
			#STDERR.puts "!#{@response_handlers[c]}"
				return @response_handlers[c].call(http_request, http_response, self)
			end

			c=c.superclass
		end	

		# if we reached this place, no handler was registered
		# for this response. default is to return the response.
		
		return http_response
	end

	# internal
	def do_http request
		response = nil

		http = Net::HTTP.new(@uri.host, @uri.port, @proxy_host,
			@proxy_port, @proxy_user, @proxy_pwd)
		http.use_ssl = @uri.scheme == 'https'
	
		# add custom request headers.
		
		@request_headers.each {|key,value|
			request[key]=value;
		}

		handle_response(request, http.request(request));
	end

	# internal
	def make_query query
		return query unless query && query.class == Hash
		query.inject([]) do |s, (key, value)|
			s << CGI::escape(key) + "=" + CGI::escape(value)
		end.join('&')
	end
	
	# Make a simple GET request to the provided URI.
	#
	# Example:
	# 	puts(SimpleHttp.get("www.example.com"))
	def self.get uri, query=nil
		http = SimpleHttp.new uri
		http.get query	
	end

	def self.head uri, query=nil
		http = SimpleHttp.new uri
		http.head query
	end

	def self.options uri
		http = SimpleHttp.new uri
		http.options 
	end

	def self.trace uri
		http = SimpleHttp.new uri
		http.trace
	end

	# Make a POST request to the provided URI.
	#
	# Example:
	# 	puts(SimpleHttp.post("www.example.com", "query"=>"my_query"))
	#
	# Alternatively, you can post any sort of data, but will have to
	# set the appriate content_type:
	#
	# 	SimpleHttp.post("http://www.example.com/", binary_data, "img/png")
	 
	def self.post uri, query=nil, content_type='application/x-www-form-urlencoded'
		http = SimpleHttp.new uri
		http.post query, content_type
	end
	
	# Call the +get+ method as an instance method if you need to
	# modify the default behaviour of the library, or set special
	# headers:
	#
	# 	http = SimpleHttp.new "www.example.com"
	# 	http.request_headers["X-Special"]="whatever"
	# 	str = http.get 
	def get query = nil
		if (query = make_query query)
			@uri.query = @uri.query ? @uri.query+"&"+query : query
		end
		full_path = @uri.path + (@uri.query ? "?#{@uri.query}" : "")
			
		req = Net::HTTP::Get.new(full_path)
		# puts Net::HTTP::Proxy(@proxy_host, @proxy_port, @proxy_user, @proxy_pwd).get(@uri)
		do_http req
	end

	# Call the +head+ method as an instance method.
	#
	def head query = nil
		if (query = make_query query)
			@uri.query = @uri.query ? @uri.query+"&"+query : query
		end
		full_path = @uri.path + (@uri.query ? "?#{@uri.query}" : "")
			
		req = Net::HTTP::Head.new(full_path)
		# puts Net::HTTP::Proxy(@proxy_host, @proxy_port, @proxy_user, @proxy_pwd).get(@uri)
		do_http req
	end
	
	# Call http +options+ method. Returns the response
	def options
		# we don't support sending a payload in options' body.
		req = Net::HTTP::Options.new(@uri.path)
		do_http req
	end

	def trace
		# payload? 
		req = Net::HTTP::Trace.new(@uri.path)
		do_http req
	end

	#
	#	Post the query data to the url. 
	#	The body of the request remains empty if query=nil.
	#	In case `query` is a `Hash`, it's assumed that we are
	#	sending a form.
	#	In case `query` is a `String`, it's also assumed that a
	#	form is being sent, UNLESS the `content_type` parameter
	#	is set.
	#
	def post query=nil, content_type='application/x-www-form-urlencoded'
		req = Net::HTTP::Post.new(@uri.path)

		req.body= make_query query if query
		req.content_type=content_type if query
		req.content_length=query ? req.body.length : 0

		do_http req
	end
	
end

#ht = SimpleHttp.new "http://www.google.com/aldfksjaldskjfalskjfdlk"
##ht.register_response_handler(Net::HTTPRedirection) {|req, res, ht| puts res['location']}
#puts ht.get.class
##puts(ht.get("q"=>"bla"))
#
##puts (SimpleHttp.get "http://www.google.com")
#
#['http://www.google.com/', 'www.google.com', 'https://www.google.com'].each {|u|
#	SimpleHttp.new u
#}
##puts ht.post


