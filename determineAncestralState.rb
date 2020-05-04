#! /usr/bin/env ruby



##################################################################
require 'getoptlong'


##################################################################
indir = nil
states = Array.new
type = nil
mode = 'mcmc'
bf_range = -10000...10000
is_iTOL = false

indirs = Array.new
lnL_info = Hash.new{|h,k|h[k]={}}


##################################################################
def get_node_indirs(indirs)
  infiles = indirs.map{|i|File.join(i, 'list')}.select{|i|File.exists?(i)}
  return(infiles)
end


def get_node2taxa(infiles)
  node2taxa = Hash.new
  infiles.each do |infile|
    in_fh = File.open(infile, 'r')
    in_fh.each_line do |line|
      line.chomp!
      name, taxon1, taxon2 = line.split("\t")[0,3]
      node2taxa[name] = [taxon1, taxon2]
    end
    in_fh.close
  end
  return(node2taxa)
end


def get_lnL(stone_infile, mode)
  lnL = nil
  in_fh = File.open(stone_infile, 'r')
  line = in_fh.readlines[-1]
  return(lnL) if line.nil?

  case mode
    when 'mcmc'
      if line =~ /^Log marginal likelihood:\s+(.+)$/
        lnL = $1.to_f
      end
    when 'ml'
      lnL = line.split("\t")[1].to_f
  end
  in_fh.close
  return(lnL)
end


##################################################################
opts = GetoptLong.new(
  ['--indir', GetoptLong::REQUIRED_ARGUMENT],
  ['--state', GetoptLong::REQUIRED_ARGUMENT],
  ['--type', GetoptLong::REQUIRED_ARGUMENT],
  ['--mode', GetoptLong::REQUIRED_ARGUMENT],
  ['--bf_range', GetoptLong::REQUIRED_ARGUMENT],
  ['--iTOL', '--itol', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when /^--indir$/
      indir = value
    when /^--state$/
      states << value.split(',')
    when /^--type$/
      type = value
    when /^--mode$/
      mode = value
    when /^--bf_range$/
      min, max = value.split(',').map{|i|i.to_f}
      bf_range = Range.new(min, max)
    when /^--itol$/i
      is_iTOL = true
  end
end


states.flatten!
if type.nil?
  STDERR.puts "--type not given! Exiting ......"
  exit 1
end


case mode
  when 'ml'
    lnl_file_basename = 'species.trait.Log.txt'
  when 'mcmc'
    lnl_file_basename = 'species.trait.Stones.txt'
end


##################################################################
Dir.foreach(indir).each do |b|
  next if b =~ /^\./
  indirs << File.join(indir, b)
end

infiles = get_node_indirs(indirs)

node2taxa = get_node2taxa(infiles)

indirs.each do |indir|
  name = File.basename(indir)
  Dir.foreach(indir) do |b|
    next if b != type
    next if b =~ /^\./ if b != type
    sub_indir = File.join(indir, b)
    next if File::file?(sub_indir)
    Dir.foreach(sub_indir) do |b1|
      next if b1 =~ /^\./
      sub_indir2 = File.join(sub_indir, b1)
      Dir.foreach(sub_indir2) do |b2|
        stone_infile = File.join(sub_indir2, b2, lnl_file_basename)
        stone_infile = `ls #{sub_indir2}/#{b2}/*Stones.txt 2>/dev/null`.chomp
        next if not File.exists?(stone_infile)
        lnL = get_lnL(stone_infile, mode)
        lnL_info[b1][b2] = lnL
      end
    end
  end
end


##################################################################
lnL_info.each_pair do |name, v|
  next if not node2taxa.include?(name)
  next if not (v.include?(states[0]) and v.include?(states[1]))
  next if states.any?{|i|v[i].nil?}
  bf = states.map{|i|v[i]}.reduce(:-) * 2
  taxa_str = node2taxa[name].join('|')
  next unless bf_range.include?(bf)
  puts [taxa_str, bf].join(",")
end
#for i in `seq 7`; do a=`tail -1 Rhizobium-Agro-$i/FM/species.trait.Stones.txt|cut -f2`; b=`tail -1 Rhizobium-Agro-$i/fV/species.trait.Stones.txt|cut -f2`; echo -ne "$i\t"; echo "scale=2; 2*($b - $a)"|bc; done


