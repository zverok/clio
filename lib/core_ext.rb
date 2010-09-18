class Object
    undef :id if respond_to?(:id)

    def _n; self end

    def m?(m, *arg, &block)
        respond_to?(m) ? send(m, *arg, &block) : nil
    end
end

class NilClass
    def _n; 
        NullObject.new
    end
end

class NullObject
    def method_missing(*a, &b)
        #eating silently
        nil
    end

    def to_s; '' end
end

class Numeric
    def non_zero?; !zero? end

    def sign; self < 0 ? -1 : 1 end
    def sign_str; self < 0 ? '-' : '+' end

    def normalize(min, max)
		if self < min
			min
		elsif self > max
			max
		else
			self
		end
	end
end

module Enumerable
    def group_by
        inject({}) do |groups, element|
            (groups[yield(element)] ||= []) << element
            groups
        end
    end

    def group_ordered_by
        res = []
        groups = Hash.new{|h, k| res << [k, []]; h[k] = res.last.last}
        each do |element|
            groups[yield(element)] << element
        end
        res
    end

    def uniq_with
        new_one = []
        self.each do |item| 
            new_one << item unless new_one.detect{|new_item| yield(item, new_item)}
        end
        new_one
    end

    def uniq_by
        self.uniq_with{|i1, i2| yield(i1) == yield(i2)}
    end

    def reverse_uniq_with
        new_one = []
        self.reverse.each do |item| 
            new_one << item unless new_one.detect{|new_item| yield(item, new_item)}
        end
        new_one.reverse
    end

    def reverse_uniq_by
        self.reverse_uniq_with{|i1, i2| yield(i1) == yield(i2)}
    end
end

class Array
    alias :count :size

    def count_if(&block)
        select(&block).count
    end

    def sum
		case size
            when 0; nil
            when 1; first
            else  ; self[1..-1].inject(self.first) { |sum, x| sum + x }
        end
    end

    def compact_ext
        reject{|v| !v}
    end

    def compact_ext2
        reject{|v| !v || v.empty?}
    end

    if RUBY_VERSION < '1.8.7'
        alias :dumb_flatten :flatten

        def flatten(depth = nil)
            return dumb_flatten unless depth
            return self if depth.zero?
            res = []
            self.each{|obj| 
                if obj.is_a?(Array)
                    res += obj.flatten(depth-1)
                else 
                    res << obj 
                end
            }
            res
        end
    end

    def construct_hash; Hash[*self.flatten(1)] end

	def resize!(newsize, val = nil)
		if newsize < size
			slice!(0, newsize)
		else
			fill(val, size, newsize-size)
		end
	end

    def resize(newsize, val = nil)
        self.dup.resize!(newsize, val)
    end

	def strip_last!
		self.pop while !self.empty? && self.last.nil?
		self
	end
    
	def strip_last
		self.dup.strip_last!
	end

    def single?; size == 1 end

    def singularize; self.size == 1 ? self.first : self end

    def or_if_empty(other)
        self.empty? ? other : self
    end

    def min_by(&block)
        self.sort_by(&block).first
    end

    def max_by(&block)
        self.sort_by(&block).last
    end

    def split
        lists = [[]]
        self.each{|obj| yield(obj) ? lists << [] : lists.last << obj}
        lists
    end

    def non_empty?; !empty? end

    def set_values_at(indexes, values)
        indexes.zip(values).each{|i,v| self[i] = v}
    end

    def replace_value(oldval, newval)
        self.map{|v| v == oldval ? newval : v}
    end

    def group_by_count(cnt)
        (0..(size/cnt)).map{|idx| self[(idx*cnt)..((idx+1)*cnt-1)]}.reject(&:empty?)
    end

    def cond_zip(other, &block)
        other = other.dup
        self.map{|i1| [i1, other.detect{|i2| block[i1, i2]}]}
    end

    def detect_by(val, &block)
        detect{|o| block[o] == val}
    end

    def join_lines
        compact_ext.reject(&:empty?).join("\n")
    end
end

class Hash
    # Usage { :a => 1, :b => 2, :c => 3}.except(:a) -> { :b => 2, :c => 3}
    def except(*keys)
        self.reject { |k,v|
            keys.include? k
        }
    end

    alias :extract :delete

    def +(other)
        self.update(other){|key, old_val, new_val| 
            case old_val
                when Hash   ; old_val.merge(new_val)
                when Array  ; old_val + new_val
                else        ; new_val
            end
        }
    end

    def -(other)
        reject{|k, v| other[k] == v}
    end

    def zip(other)
        self.map{|k,v| [k, v, other[k]]}
    end
end

class String
    def to_f_ext
        gsub(',', '.').to_f
    end

    def non_empty?; !empty? end

    def to_single_line(delim = '; ')
        gsub("\n", delim)
    end

    if RUBY_VERSION < '1.9.0'
        def force_encoding(*arg); self end
    end

    def force_utf8; force_encoding('UTF-8') end

    def surround(before, after); before + self + after end

    if RUBY_VERSION < '1.8.7'
        alias :bytesize :size
    end
end

class Range
    def normalize
        (self.begin > self.end) ? (self.end..self.begin) : self
    end

    def transform(b, e)
        exclude_end? ? (b...e) : (b..e)
    end

    def limit(b, e)
        transform([b, self.begin].max, [e, self.end].min)
    end

    def -(el)
        transform(self.begin - el, self.end - el)
    end

    def empty?; count.zero? end
end

class Float
    def round_digits(d)
        decimals = 10**d
        (self * decimals).round.to_f / decimals
    end
end

class Exception
    def backtrace_
        backtrace.join("\n")
    end
end

class File
    def File.write(path, contents, flags = '')
        File.open(path, "w#{flags}"){|of| of.write contents}
    end

    def File.append(path, contents, flags = '')
        File.open(path, "a#{flags}"){|of| of.write contents}
    end
end

if RUBY_VERSION < '1.8.7'
    # :stopdoc:
    #instance_exec stolen from facets-1.8.8
    module Kernel
        def instance_exec(*arguments, &block)
            if block
                block.bind(self)[*arguments]
            else
                raise RuntimeError, "No block for instance_exec on #{self}"
            end
        end
    end

    class Proc
        def bind(object=nil)
            object ||= eval("self", self)
            block = self
            store = Object
            begin
                old, Thread.critical = Thread.critical, true
                #n=0; n+=1 while store.method_defined?(name="_bind_#{n}")
                name="_bind_#{block}"
                store.module_eval do
                    define_method name, &block
                end
                return object.method(name)
            ensure
                store.module_eval do
                    remove_method name #rescue nil
                    #undef_method name #rescue nil
                end
                Thread.critical = old
            end
        end
    end

    # :startdoc:

    #(c) ActiveSupport
    class Symbol
        def to_proc
          Proc.new { |*args| args.shift.__send__(self, *args) }
        end
    end

    class Object
        def tap
            yield self
            self
        end
    end
end
