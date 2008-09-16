options = { :irb => 'irb' }

ENV['ANTFARM_ENV'] = ARGV.shift
libs =  " -r irb/completion"
libs << %( -r "#{ANTFARM_ROOT}/config/environment")

puts "Loading #{ENV['ANTFARM_ENV']} environment"

exec "#{options[:irb]} #{libs} --simple-prompt"
