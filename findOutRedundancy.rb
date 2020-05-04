#! /usr/bin/env ruby


#######################################################################
require 'getoptlong'
require 'set'

require 'chang_yong'


#######################################################################
infile = nil
treefile = nil
outfile = nil
include_list_file = nil


it2it = Hash.new{|h,k|h[k]=[]} #identical taxon
genomesToRemove = Array.new
species_included = Hash.new


#######################################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['-t', '--tree', GetoptLong::REQUIRED_ARGUMENT],
  ['-o', GetoptLong::REQUIRED_ARGUMENT],
  ['--include_list', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
    when '--include_list'
      include_list_file = value
    when '-t', '--tree'
      treefile = value
    when '-o'
      outfile = value
  end
end


#######################################################################
species_included = read_list(include_list_file) if not include_list_file.nil?


#######################################################################
in_fh = File.open(infile, 'r')
in_fh.each_line do |line|
  line.chomp!
  next unless line =~ /identical to/
  line =~ /^NOTE: ([A-Za-z0-9_-]+) (is |\()identical to ([A-Za-z0-9_-]+)/
  it2it[$1] << $3
  it2it[$3] << $1
end
in_fh.close


#######################################################################
s = it2it.keys.to_set
a = s.divide{|a,b|it2it[a].include?(b)}.to_a

a.each do |i|
  if not (i.to_a & species_included.keys).empty?
    genomesToRemove << (i.to_a).select{|x|not species_included.include?(x)}
  else
    genomesToRemove << (i.to_a)[1, i.size-1]
  end
end


#######################################################################
genomesToRemove.flatten!

#puts genomesToRemove.size
if treefile.nil?
  puts genomesToRemove.join(' ')
else
  output = `nw_prune #{treefile} #{genomesToRemove.join(' ')}`.chomp
  puts output
end


