#! /usr/bin/env ruby


#######################################################
require 'getoptlong'

require 'Dir'


#######################################################
infile = nil
valueInfo = Hash.new{|h,k|h[k]=[]}
is_prop_zero = false
outdir = nil
is_force = false

regexps = Array.new


#######################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['--regexp', GetoptLong::REQUIRED_ARGUMENT],
  ['--prop_zero', GetoptLong::NO_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
    when '--regexp'
      regexps << value.split(',')
    when '--prop_zero'
      is_prop_zero = true
    when '--outdir'
      outdir = value
    when '--force'
      is_force = true
  end
end


regexps.flatten!
regexps.map!{|i| Regexp.new(/^#{i}/) }
mkdir_with_force(outdir, is_force) unless is_prop_zero


#######################################################
is_start = false
features = Array.new

in_fh = File.open(infile, 'r')
in_fh.each_line do |line|
  line.chomp!
  #Iteration	Lh	Tree No	No Off Parmeters	No Off Zero	Model string	qFM	qFV	qFf	qMF	qMV	qMf	qVF	qVM	qVf	qfF	qfM	qfV	Root P(F)	Root P(M)	Root P(V)	Root P(f)	
  if line =~ /^Iteration\t/
    is_start = true
    features = line.split("\t").map{|i|i.gsub(' ', '_')}
    next
  end
  next if not is_start
  #1001000	-482.077236	753	3	1	'Z 1 0 0 0 0 0 0 2 0 0 1 	0.000000	34.200434	2.097804	2.097804	2.097804	2.097804	2.097804	2.097804	79.968316	2.097804	2.097804	34.200434	0.326511	0.073653	0.299918	0.299918	
  line_arr = line.split("\t")
  features.zip(line_arr) do |feature, value|
    valueInfo[feature] << value
  end
end
in_fh.close


#######################################################
valueInfo.each_pair do |feature, values|
  if regexps.any?{|r| feature =~ r }
    if is_prop_zero
      puts [feature, values.count{|v|v.to_f == 0}/values.size.to_f].join("\t")
    else
      puts feature
      outfile = File.join(outdir, feature+'.list')
      out_fh = File.open(outfile, 'w')
      out_fh.puts values.join("\n") 
      out_fh.close
    end
  end
end


