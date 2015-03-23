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

  def userpic_path(userid)
    if userid =~ %r{^filter/}
      userid = context.clio.user
    elsif userid.include?('/')
      userid = userid.sub(%r{/.+$}, '')
    end
    relative(context.path_("images/userpics/#{userid}.jpg"))
  end

  def thumbnail_path(url)
    if local_img?(url)
      f = Dir[context.path("images/media/thumbnails/#{url.sub(%r{.+/}, '')}.*")].first
      if f
        relative(context.path_("images/media/thumbnails/#{File.basename(f)}"))
      else
        url
      end
    else
      url
    end
  end

  def image_path(url)
    if local_img?(url) && File.exists?(context.json_path('images.tsv'))
      @image_map ||= File.read(context.json_path('images.tsv')).split("\n").
                  map{|ln| ln.split("\t")}.to_h

      if fname = @image_map[url]
        relative(context.path_("images/media/#{fname}"))
      else
        context.clio.log.warn("Картинка #{url} не скачана!")
        url
      end
    else
      url
    end
  end

  def file_path(url)
    if File.exists?(context.json_path('files.tsv'))
      @file_map ||= File.read(context.json_path('files.tsv')).split("\n").
                    map{|ln| ln.split("\t")}.to_h

      fname = @file_map[url] or
        fail("Файл #{url} не скачан!")

      relative(context.path_("files/#{fname}"))
    else
      url
    end
  end

  def friendly_filesize(bytes)
    if bytes < 1024*1024
      '%i KB' % (bytes.to_f / 1024)
    else
      '%.1f MB' % (bytes.to_f / (1024*1024))
    end
  end

  private

  def local_img?(url)
    url.include?('http://m.friendfeed-media.com/') ||
        url.include?('http://i.friendfeed.com/')
  end
end
