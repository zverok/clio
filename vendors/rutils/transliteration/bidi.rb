# coding:utf-8
# Реализует транслитерацию "в обе стороны", дающую возможность автоматически использовать URL как ключ записи
module RuTils::Transliteration::BiDi
  TABLE_TO = {
    "А"=>"A","Б"=>"B","В"=>"V","Г"=>"G","Д"=>"D",
    "Е"=>"E","Ё"=>"JO","Ж"=>"ZH","З"=>"Z","И"=>"I",
    "Й"=>"JJ","К"=>"K","Л"=>"L","М"=>"M","Н"=>"N",
    "О"=>"O","П"=>"P","Р"=>"R","С"=>"S","Т"=>"T",
    "У"=>"U","Ф"=>"F","Х"=>"KH","Ц"=>"C","Ч"=>"CH",
    "Ш"=>"SH","Щ"=>"SHH","Ъ"=>"_~","Ы"=>"Y","Ь"=>"_'",
    "Э"=>"EH","Ю"=>"JU","Я"=>"JA","а"=>"a","б"=>"b",
    "в"=>"v","г"=>"g","д"=>"d","е"=>"e","ё"=>"jo",
    "ж"=>"zh","з"=>"z","и"=>"i","й"=>"jj","к"=>"k",
    "л"=>"l","м"=>"m","н"=>"n","о"=>"o","п"=>"p",
    "р"=>"r","с"=>"s","т"=>"t","у"=>"u","ф"=>"f",
    "х"=>"kh","ц"=>"c","ч"=>"ch","ш"=>"sh","щ"=>"shh",
    "ъ"=>"~","ы"=>"y","ь"=>"'","э"=>"eh","ю"=>"ju",
    "я"=>"ja",
    # " "=>"__","_"=>"__"
    # так сразу не получится, будут проблемы с "Ь"=>"_'"
  }.sort do |one, two|
    two[1].split(//).size <=> one[1].split(//).size
  end

  TABLE_FROM = TABLE_TO.unshift([" ","__"]).clone
  TABLE_TO.unshift(["_","__"])

  def self.translify(str, allow_slashes = true)
    slash = allow_slashes ? '/' : '';

    s = str.clone.gsub(/[^\- _0-9a-zA-ZА-ёЁ#{slash}]/, '')
    lang_fr = s.scan(/[А-ёЁ ]+/)
    lang_fr.each do |fr|
      TABLE_TO.each do | translation |
        fr.gsub!(/#{translation[0]}/, translation[1])
      end
    end

    lang_sr = s.scan(/[0-9A-Za-z\_\-\.\/\']+/)

    string = ""
    if s =~ /\A[А-ёЁ ]/
      lang_fr, lang_sr = lang_sr, lang_fr
      string = "+"
    end

    0.upto([lang_fr.length, lang_sr.length].min-1) do |x|
      string += lang_sr[x] + "+" + lang_fr[x] + "+";
    end

    if (lang_fr.length < lang_sr.length)
      string += lang_sr[lang_sr.length-1]
    else
      string[0, string.length-1]
    end
  end

  def self.detranslify(str, allow_slashes = true)
    slash = allow_slashes ? '/' : '';

    str.split('/').inject(out = "") do |out, pg|
      strings = pg.split('+')
      1.step(strings.length-1, 2) do |x|
        TABLE_FROM.each do | translation |
          strings[x].gsub!(/#{translation[1]}/, translation[0])
        end
      end
      out << slash << strings.to_s
    end
    out[slash.length, out.length-slash.length]
  end
end
