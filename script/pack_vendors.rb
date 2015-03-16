# encoding: utf-8
list = `bundle`.split("\n").grep(/^Using/).map{|ln| ln.scan(/^Using (\S+) (\S+)$/).flatten.join('-')}.
    reject{|s| s.include?('bundler')}

list.each do |gem|
    `cp vendor/bundle/gems/#{gem}/lib/ . -r`
    #`cp vendor/bundle/gems/#{gem}/lib/**/*.* lib`
end
