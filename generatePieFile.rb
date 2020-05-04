#! /usr/bin/env ruby


##############################################################
require 'getoptlong'
require 'find'
require 'simple_stats'
require 'ruby_native_statistics'

require 'Dir'


##############################################################
infile = nil
list_indir = nil
is_pie = false
is_full = false
is_iTOL = false
outdir = nil
is_force = false
is_tolerate = false


full_info = Hash.new{|h,k|h[k]={}}
node_info = Hash.new{|h,k|h[k]={}}
name2taxa = Hash.new


##############################################################
TRAITS = %w[P(F) P(M) P(f) P(V) P(R)]


##############################################################
class NodeInfo
  attr_accessor :median, :mean, :stdev
  def initialize(median, mean, stdev)
    @median = median
    @mean = mean
    @stdev = stdev
  end
end


##############################################################
def read_list_indir(list_indir)
  name_info = Hash.new
  Find.find(list_indir) do |path|
    b = File.basename(path)
    if b == 'list'
      in_fh = File.open(path)
      in_fh.each_line do |line|
        line.chomp!
        next if line =~ /^$/
        name, taxon1, taxon2 = line.split("\t")[0,3]
        name_info[name] = [taxon1, taxon2]
      end
      in_fh.close
    end
  end
  return(name_info)
end


##############################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['--list_indir', GetoptLong::REQUIRED_ARGUMENT],
  ['--pie', GetoptLong::NO_ARGUMENT],
  ['--full', GetoptLong::NO_ARGUMENT],
  ['--iTOL', '--itol', GetoptLong::NO_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
  ['--tolerate', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when /^-i$/
      infile = value
    when /^--list_indir$/
      list_indir = value
    when /^--pie$/
      is_pie = true
    when /^--full$/
      is_full = true
    when /^--iTOL$/i
      is_iTOL = true
    when /^--outdir$/
      outdir = value
    when /^--force$/
      is_force = true
    when /^--tolerate$/
      is_tolerate = true
  end
end


##############################################################
if not list_indir.nil?
  name_info = read_list_indir(list_indir)
  name_info.each_pair do |name, taxa|
    puts [name, taxa].flatten.join("\t") if not is_iTOL
    name2taxa[name] = taxa
  end
end


##############################################################
#Iteration	Lh	Tree No	qFM	qFV	qFf	qMF	qMV	qMf	qVF	qVM	qVf	qfF	qfM	qfV	Root P(F)	Root P(M)	Root P(V)	Root P(f)	
categories = Array.new
is_read_data_start = false
value_info = Hash.new{|h,k|h[k]=[]}

in_fh = File.open(infile, 'r')
in_fh.each_line do |line|
  line.chomp!
  line_arr = line.split("\t")
  if is_read_data_start
    categories.zip(line_arr) do |category, value|
      value_info[category] << value.to_f
    end
  end
  if line =~ /^Iteration\t/
    categories = line_arr
    is_read_data_start = true
  end
end
in_fh.close



##############################################################
value_info.sort.to_h.each_pair do |category, values|
  next if categories[0,3].include?(category)
  full_info[category] = NodeInfo.new(values.median, values.mean, values.stdev)
  if category =~ /^(.+) (.+)$/
    node_info[$1][$2] = NodeInfo.new(values.median, values.mean, values.stdev)
  end
end


if is_full
  full_info.each_pair do |category, v|
    puts category
  end
elsif is_pie
  mkdir_with_force(outdir, is_force, is_tolerate)
  node_info.each_pair do |node, v|
    outfile = File.join(outdir, node)
    out_fh = File.open(outfile, 'w')
    if is_iTOL
      if name2taxa.include?(node)
        puts [name2taxa[node].join('|'), 1, 10, [v.sort_by{|i|TRAITS.index(i[0])}.map{|trait, full_info|full_info.mean}]].flatten.join(',')
      else
        STDERR.puts "Warning! #{node} is not present!"
      end
    end
    out_fh.puts [v.sort_by{|i|TRAITS.index(i[0])}.map{|trait, full_info|full_info.mean}].flatten.join("\t")
    out_fh.close
  end
end


