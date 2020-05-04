#! /usr/bin/env ruby


#################################################
DIR = File.dirname($0)
$: << File.join(DIR, 'lib')


#################################################
require 'getoptlong'

require 'tree'


#################################################
infile = nil
trait_file = nil

taxon2trait = Hash.new
num2taxon = Hash.new
taxa = Array.new
is_translate = false


#################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['--trait', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
    when '--trait'
      trait_file = value
  end
end


#################################################
in_fh = File.open(trait_file, 'r')
in_fh.each_line do |line|
  line.chomp!
  taxon, trait = line.split("\t")
  taxon2trait[taxon] = trait
end
in_fh.close


lines = Array.new
in_fh = File.open(infile, 'r')
in_fh.each_line do |line|
  line.chomp!
  lines << line

  if line =~ /^\s*TRANSLATE/
    is_translate = true
    next
  end
  if is_translate
    is_translate = false if line =~ /;$/
    line =~ /(\S+)\t([^,]+),?$/
    num = $1
    taxon = $2
    num2taxon[num] = taxon
  end

  if line =~ /^\t+TREE [^()]+ (\( .+ \);)$/x
    nwk_str = $1
    nwk = Bio::Newick.new(nwk_str)
    tree = nwk.tree()
    tree.allTips.each do |tip|
      taxon = num2taxon[tip.name]
      taxa << taxon
    end
  end
end
in_fh.close
lines << ''


#################################################
lines << <<EOF
begin characters;
  dimensions nchar=1;
  format datatype=standard;
  matrix
EOF


lines << taxon2trait.delete_if{|k,v|not taxa.include?(k)}.map{|k,v| '    '+k+"\t"+v}.join("\n")
lines << 'end'


#################################################
# OUTPUT
lines.each do |line|
  line.gsub!('-', '_')
  puts line
end


