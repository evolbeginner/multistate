#! /usr/bin/env ruby


########################################################################
require 'getoptlong'

require 'Dir'


########################################################################
mode = 'mcmc'
outdir = nil
fossils = Array.new
restrictions = Array.new
stones = [100, 10000]
no_iterations = 1100000
burnin = 100000
add_cmds = Array.new
is_force = false
is_tolerate = false


########################################################################
opts = GetoptLong.new(
  ['--mode', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--fossil', GetoptLong::NO_ARGUMENT],
  ['--res', GetoptLong::REQUIRED_ARGUMENT],
  ['--stones', GetoptLong::REQUIRED_ARGUMENT],
  ['--iteration', GetoptLong::REQUIRED_ARGUMENT],
  ['--burnin', GetoptLong::REQUIRED_ARGUMENT],
  ['--stringent', GetoptLong::NO_ARGUMENT],
  ['--more_stringent', '--more_st', GetoptLong::NO_ARGUMENT],
  ['--add_cmd', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
  ['--tolerate', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when /^--mode$/
      mode = value
    when /^--outdir$/
      outdir = value
    when /^--fossil$/
      fossils << value
    when /^--res$/
      restrictions << value
    when /^--stones$/
      stone = value
    when /^--iteration$/
      no_iterations = value.to_i
    when /^--burnin$/
      burnin = value.to_i
    when /^--stringent$/
      stones = [1000, 10000]
      burnin = 1000000
      no_iterations = 11000000
    when '--more_stringent', '--more_st'
      stones = [1000, 10000]
      burnin = 10000000
      no_iterations = 110000000
    when /^--add_cmd$/
      add_cmds << value
    when /^--force$/
      is_force = true
    when /^--tolerate$/
      is_tolerate = true
  end
end


########################################################################
mkdir_with_force(outdir, is_force, is_tolerate)

outfile = File.join(outdir, mode+'.txt')
out_fh = File.open(outfile, 'w')


########################################################################
out_fh.puts 1
out_fh.puts mode == 'ml' ? 1 : 2
out_fh.puts

fossils.each do |fossil|
  out_fh.puts "fossil #{fossil}"
end

restrictions.each do |restrict|
  res_str = restrict.split(/[-,]/).join(' ')
  out_fh.puts "restrict #{res_str}"
end

if mode == 'mcmc'
  if not stones.empty?
    stones_str = stones.join(' ')
    out_fh.puts "Stones #{stones_str}"
  end
  out_fh.puts "Iterations #{no_iterations}"
  out_fh.puts "burnin #{burnin}"
end

add_cmds.each do |add_cmd|
  out_fh.puts "#{add_cmd}"
end


############################################################
out_fh.puts
out_fh.puts 'run'

out_fh.close


