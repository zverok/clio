# encoding: utf-8
class Helpers
  def initialize(context, path)
    @context = context
    @depth = path.scan('/').count
    @regions_hash={}
  end

  attr_reader :context

  def content_for(region, &blk)  
    @regions_hash[region] = blk.call
  end
  
  def relative(link)
    '../'*@depth+link
  end

  def partial(template, options = {})
    context.haml("_#{template}").render(self, Mash.new(options))
  end

  def to_filename(text)
    context.make_filename(text)
  end

  def [](region)
    @regions_hash[region]
  end
end
