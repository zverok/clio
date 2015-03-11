# encoding: utf-8
#module Haml
  #module Helpers
    #def partial(template, options = {})
      #haml = Haml::Engine.new(File.read("#{Clio.haml_templates_path}/_#{template}.haml"))
      #haml.render(Hashie::Mash.new(options))
    #end
  #end
#end

class Helpers
  def initialize(path)
    @depth = path.scan('/').count
    @regions_hash={}
  end

  def content_for(region, &blk)  
    @regions_hash[region] = blk.call
  end
  
  def relative(link)
    '../'*@depth+link
  end

  def partial(template, options = {})
    haml = Haml::Engine.new(File.read("#{Clio.haml_templates_path}/_#{template}.haml"))
    haml.render(self, Hashie::Mash.new(options))
  end

  def [](region)
    @regions_hash[region]
  end
end
