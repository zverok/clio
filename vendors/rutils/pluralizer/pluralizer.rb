# coding:utf-8
module RuTils
  module Pluralization #:nodoc:
    # Выбирает нужный падеж существительного в зависимости от числа
    def self.choose_plural(amount, *variants)
      variant = (amount%10==1 && amount%100!=11 ? 1 : amount%10>=2 && amount%10<=4 && (amount%100<10 || amount%100>=20) ? 2 : 3)
      variants[variant-1]
    end

    def self.rublej(amount)
      pts = []
      
      pts << RuTils::Pluralization::sum_string(amount.to_i, 1, "рубль", "рубля", "рублей") unless amount.to_i == 0
      if amount.kind_of?(Float)
        remainder = (amount.divmod(1)[1]*100).round
        if (remainder == 100)
          pts = [RuTils::Pluralization::sum_string(amount.to_i+1, 1, 'рубль', 'рубля', 'рублей')]
        else
          pts << RuTils::Pluralization::sum_string(remainder.to_i, 2, 'копейка', 'копейки', 'копеек')
        end
      end
      
      pts.join(' ')
    end
    
    #  Выполняет преобразование числа из цифрого вида в символьное
    #   amount - числительное
    #   gender   = 1 - мужской, = 2 - женский, = 3 - средний
    #   one_item - именительный падеж единственного числа (= 1)
    #   two_items - родительный падеж единственного числа (= 2-4)
    #   five_items - родительный падеж множественного числа ( = 5-10)
    def self.sum_string(amount, gender, one_item='', two_items='', five_items='')
        into = ''
        tmp_val ||= 0

        return "ноль " + five_items if amount == 0

        tmp_val = amount

        # единицы
        into, tmp_val = sum_string_fn(into, tmp_val, gender, one_item, two_items, five_items)

        return into if tmp_val == 0

        # тысячи
        into, tmp_val = sum_string_fn(into, tmp_val, 2, "тысяча", "тысячи", "тысяч") 

        return into if tmp_val == 0

        # миллионы
        into, tmp_val = sum_string_fn(into, tmp_val, 1, "миллион", "миллиона", "миллионов")

        return into if tmp_val == 0

        # миллиардов
        into, tmp_val = sum_string_fn(into, tmp_val, 1, "миллиард", "миллиарда", "миллиардов")
        return into
    end
    
    private
    def self.sum_string_fn(into, tmp_val, gender, one_item='', two_items='', five_items='')
      rest, rest1, end_word, ones, tens, hundreds = [nil]*6
      #
      rest = tmp_val % 1000
      tmp_val = tmp_val / 1000
      if rest == 0 
        # последние три знака нулевые 
        into = five_items + " " if into == ""
        return [into, tmp_val]
      end
      #
      # начинаем подсчет с Rest
      end_word = five_items
      # сотни
      hundreds = case rest / 100
        when 0 then ""
        when 1 then "сто "
        when 2 then "двести "
        when 3 then "триста "
        when 4 then "четыреста "
        when 5 then "пятьсот "
        when 6 then "шестьсот "
        when 7 then "семьсот "
        when 8 then "восемьсот "
        when 9 then "девятьсот "
      end

      # десятки
      rest = rest % 100
      rest1 = rest / 10
      ones = ""
      case rest1
        when 0 then tens = ""
        when 1 # особый случай
          tens = case rest
            when 10 then "десять "
            when 11 then "одиннадцать "
            when 12 then "двенадцать "
            when 13 then "тринадцать "
            when 14 then "четырнадцать "
            when 15 then "пятнадцать "
            when 16 then "шестнадцать "
            when 17 then "семнадцать "
            when 18 then "восемнадцать "
            when 19 then "девятнадцать "
          end
        when 2 then tens = "двадцать "
        when 3 then tens = "тридцать "
        when 4 then tens = "сорок "
        when 5 then tens = "пятьдесят "
        when 6 then tens = "шестьдесят "
        when 7 then tens = "семьдесят "
        when 8 then tens = "восемьдесят "
        when 9 then tens = "девяносто "
      end
      #
      if rest1 < 1 or rest1 > 1 # единицы
        case rest % 10
          when 1
            ones = case gender
              when 1 then "один "
              when 2 then "одна "
              when 3 then "одно "
            end
            end_word = one_item
          when 2
            if gender == 2
              ones = "две "
            else
              ones = "два " 
            end       
            end_word = two_items
          when 3
            ones = "три " if end_word = two_items
          when 4
            ones = "четыре " if end_word = two_items
          when 5
            ones = "пять "
          when 6
            ones = "шесть "
          when 7
            ones = "семь "
          when 8
            ones = "восемь "
          when 9
            ones = "девять "
        end
      end

      # сборка строки
      st = ''
      return [(st << hundreds.to_s << tens.to_s  << ones.to_s << end_word.to_s << " " << into.to_s).strip, tmp_val] 
    end
    
    # Реализует вывод прописью любого объекта, реализующего Float
    module FloatFormatting
      
      # Выдает сумму прописью с учетом дробной доли. Дробная доля округляется до миллионной, или (если
      # дробная доля оканчивается на нули) до ближайшей доли ( 500 тысячных округляется до 5 десятых).
      # Дополнительный аргумент - род существительного (1 - мужской, 2- женский, 3-средний)
      def propisju(gender = 2)
        raise "Это не число!" if self.nan?
    
        st = RuTils::Pluralization::sum_string(self.to_i, gender, "целая", "целых", "целых")
  
        remainder = self.to_s.match(/\.(\d+)/)[1]
    
        signs = remainder.to_s.size- 1
        
        it = [["десятая", "десятых"]]
        it << ["сотая", "сотых"]
        it << ["тысячная", "тысячных"]
        it << ["десятитысячная", "десятитысячных"]
        it << ["стотысячная", "стотысячных"]
        it << ["миллионная", "милллионных"]
        it << ["десятимиллионная", "десятимилллионных", "десятимиллионных"]
        it << ["стомиллионная", "стомилллионных", "стомиллионных"]
        it << ["миллиардная", "миллиардных", "миллиардных"]
        it << ["десятимиллиардная", "десятимиллиардных", "десятимиллиардных"]
        it << ["стомиллиардная", "стомиллиардных", "стомиллиардных"]
        it << ["триллионная", "триллионных", "триллионных"]

        while it[signs].nil?
          remainder = (remainder/10).round
          signs = remainder.to_s.size- 1
        end

        suf1, suf2, suf3 = it[signs][0], it[signs][1], it[signs][2]
        st + " " + RuTils::Pluralization::sum_string(remainder.to_i, 2, suf1, suf2, suf2)
      end

      def propisju_items(gender=1, *forms)
        if self == self.to_i
          return self.to_i.propisju_items(gender, *forms)
        else
          self.propisju(gender) + " " + forms[1]
        end
      end

    end
    
    # Реализует вывод прописью любого объекта, реализующего Numeric
    module NumericFormatting
      # Выбирает корректный вариант числительного в зависимости от рода и числа и оформляет сумму прописью
      #   234.propisju => "двести сорок три"
      #   221.propisju(2) => "двести двадцать одна"
      def propisju(gender = 1)
        RuTils::Pluralization::sum_string(self, gender, "")
      end
      
      def propisju_items(gender=1, *forms)
        self.propisju(gender) + " " + RuTils::Pluralization::choose_plural(self.to_i, *forms)
      end
      
      # Выбирает корректный вариант числительного в зависимости от рода и числа. Например:
      # * 4.items("колесо", "колеса", "колес") => "колеса"
      def items(one_item, two_items, five_items)
        RuTils::Pluralization::choose_plural(self, one_item, two_items, five_items)
      end  
      
      # Выводит сумму в рублях прописью. Например:
      # * (15.4).rublej => "пятнадцать рублей сорок копеек"
      def rublej
        RuTils::Pluralization::rublej(self)
      end
    end
  end
end

class Object::Numeric
  include RuTils::Pluralization::NumericFormatting
end


class Object::Float
  include RuTils::Pluralization::FloatFormatting
end
