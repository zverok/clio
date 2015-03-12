# encoding: utf-8
class Helpers
  def initialize(feed, path)
    @feed = feed
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
    @feed.haml("_#{template}").render(self, Hashie::Mash.new(options))
  end

  def to_filename(text)
    @feed.make_filename(text)
  end

  def [](region)
    @regions_hash[region]
  end
end
