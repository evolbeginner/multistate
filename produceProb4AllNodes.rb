#! /usr/bin/env ruby


#######################################################
require 'getoptlong'


#######################################################
infile = nil
type = 'mcmc'


#######################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['-t', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
    when '-t'
      type = value
  end
end


#######################################################
case type
  when 'mcmc'
    puts 1
    puts 2
    puts "Stones 1000 10000"
    puts "Iterations 11000000"
    puts "burnin 1000000"
    puts
  when 'ml'
    puts 1
    puts 1
end

in_fh = infile == '-' ? STDIN : File.open(infile, 'r')
in_fh.each_line do |line|
  #MM-2  Methylocystis_sp_ATCC_49242_Rockwell  Methylosinus_sp_R-45379 F M fV  FM  fVM fVF
  line.chomp!
  line_arr = line.split("\t")
  next if line =~ /^#/
  name, taxon1, taxon2 = line_arr[0,3]
  puts ['AddTag', name, taxon1, taxon2].join(' ')
  puts ['AddMRCA', name, name].join(' ')
end

puts
puts "run"


