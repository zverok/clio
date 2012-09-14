# coding:utf-8
module RuTils
  module DateTime
  
    def self.distance_of_time_in_words(from_time, to_time = 0, include_seconds = false, absolute = false) #nodoc
      from_time = from_time.to_time if from_time.respond_to?(:to_time)
      to_time = to_time.to_time if to_time.respond_to?(:to_time)
      distance_in_minutes = (((to_time - from_time).abs)/60).round
      distance_in_seconds = ((to_time - from_time).abs).round
      
      case distance_in_minutes
        when 0..1
          return (distance_in_minutes==0) ? 'меньше минуты' : '1 минуту' unless include_seconds
        
        case distance_in_seconds
           when 0..5   then 'менее 5 секунд'
           when 6..10   then 'менее 10 секунд'
           when 11..20 then 'менее 20 секунд'
           when 21..40 then 'пол-минуты'
           when 41..59 then 'меньше минуты'
           else          '1 минуту'
         end
        
         when 2..45       then distance_in_minutes.to_s + 
                              " " + distance_in_minutes.items("минута", "минуты", "минут") 
         when 46..90     then 'около часа'
         # исключение, сдвигаем на один влево чтобы соответствовать падежу
         when 90..1440   then "около " + (distance_in_minutes.to_f / 60.0).round.to_s + 
                              " " + (distance_in_minutes.to_f / 60.0).round.items("часа", 'часов', 'часов')
         when 1441..2880 then '1 день'
         else                  (distance_in_minutes / 1440).round.to_s + 
                              " " + (distance_in_minutes / 1440).round.items("день", "дня", "дней")
       end
    end
    
    #@@ignored = "\xFF\xFF\xFF\xFF" # %% == Literal "%" character 
    @@ignored = "~~~~"
    
    def self.ru_strftime(date='%d.%m.%Y', time='')
      date.gsub!(/%%/, @@ignored)
      date.gsub!(/%a/, Date::RU_ABBR_DAYNAMES[time.wday])
      date.gsub!(/%A/, Date::RU_DAYNAMES[time.wday])
      date.gsub!(/%b/, Date::RU_ABBR_MONTHNAMES[time.mon])
      date.gsub!(/%d(\s)*%B/, time.day.to_s + '\1' + Date::RU_INFLECTED_MONTHNAMES[time.mon])
      date.gsub!(/%B/, Date::RU_MONTHNAMES[time.mon])
      date.gsub!(@@ignored, '%%')
    end
  end
end

class Date
  RU_MONTHNAMES = [nil] + %w{ январь февраль март апрель май июнь июль август сентябрь октябрь ноябрь декабрь }
  RU_DAYNAMES = %w(воскресенье понедельник вторник среда четверг пятница суббота)
  RU_ABBR_MONTHNAMES = [nil] + %w{ янв фев мар апр май июн июл авг сен окт ноя дек }
  RU_ABBR_DAYNAMES = %w(вск пн вт ср чт пт сб)
  RU_INFLECTED_MONTHNAMES = [nil] + %w{ января февраля марта апреля мая июня июля августа сентября октября ноября декабря }
  # RU_DAYNAMES_E -- оставить?
  RU_DAYNAMES_E = [nil] + %w{первое второе третье четвёртое пятое шестое седьмое восьмое девятое десятое одиннадцатое двенадцатое тринадцатое четырнадцатое пятнадцатое шестнадцатое семнадцатое восемнадцатое девятнадцатое двадцатое двадцать тридцатое тридцатьпервое}
end

class Time
  alias_method :strftime_norutils, :strftime
  
  def strftime(date)
    RuTils::DateTime::ru_strftime(date, self) #if RuTils::overrides_enabled?
    strftime_norutils(date)
  end
end