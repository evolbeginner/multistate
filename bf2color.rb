#! /usr/bin/env ruby


#####################################################################
require 'getoptlong'


#####################################################################
#COLOR_GRADIENT = %w[#00f #30f #30c #60c #609 #909 #906 #c06 #c03 #f03 #f00]
#GRADIENT = %w[#00f #30c #609 black #906 #c03 #f00]

RANGES = [-1000..-2, -2..2, 2..1000]

COLORS = ['black', 'grey', 'red']


#####################################################################
infile = nil
sep = ','
type = 'pie'


#####################################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['--sep', GetoptLong::REQUIRED_ARGUMENT],
  ['-t', '--type', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
    when '--sep'
      sep = value
    when '-t', '--type'
      type = value
  end
end


#####################################################################
in_fh = infile == '-' ? STDIN : File.open(infile, 'r')
in_fh.each_line do |line|
  line.chomp!
  line_arr = line.split(',')
  value = line_arr[-1].to_f
  RANGES.each_with_index do |range, index|
    if range.include?(value)
      index = COLORS.index(COLORS[index])
      if type == 'pie'
        colors = 0.upto(COLORS.size-1).map{|i| i == index ? 1 : 0}
        puts [line_arr[0], 1, 10, colors].flatten.join(sep)
      elsif type == 'branch'
        color = COLORS[index]
        puts [line_arr[0].split('|')[0], 'branch', color, 'normal', 1].flatten.join(sep)
      end
      next
    end
  end
end


