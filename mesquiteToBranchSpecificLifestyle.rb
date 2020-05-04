#! /usr/bin/env ruby


#########################################################
DIR = File.dirname($0)
$: << File.join(DIR, 'lib')


#########################################################
require 'getoptlong'
require 'bio'

require 'tree'


#########################################################
infile = nil
treefile = nil

tree = nil
is_translate = false
num2taxon = Hash.new
taxon2TaxonOri = Hash.new


#########################################################
#edge_dist_cats = {'15'=>'red','20'=>'yellow','28'=>'green','38'=>'blue'}
edge_dist_cats = {'15'=>'F','20'=>'M','28'=>'V','38'=>'f'}


#########################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['-t', '--nwk', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
    when '-t', '--nwk'
      treefile = value
  end
end


#########################################################
tree0 = getTreeObjs(treefile).shift
tree0.allTips.each do |tip|
  taxon2TaxonOri[tip.name.gsub(/[ -]/, '_')] = tip.name.gsub(' ', '_')
  #taxon2TaxonOri[tip.name] = tip.name
end


#########################################################
in_fh = File.open(infile, 'r')
in_fh.each_line do |line|
  line.chomp!

  if line =~ /^\s*TRANSLATE/
    is_translate = true
    next
  end
  if is_translate
    is_translate = false if line =~ /;$/
    line =~ /(\S+)\t([^,]+).$/
    num = $1
    taxon = $2
    num2taxon[num] = taxon
  end

  if line =~ /^\t+TREE [^()]+ (\( .+ ;)$/x
    nwk_str = Marshal.load(Marshal.dump($1))
    #[&map={20}]0.0208191387
    nwk_str.gsub!(/\[\&map=\{([0-9]+)\}\][0-9.]+/, '\1')
    nwk = Bio::Newick.new(nwk_str)
    tree = nwk.tree()
  end
end
in_fh.close


tree.allTips.each do |tip|
  tip.name = taxon2TaxonOri[num2taxon[tip.name]]
end


#########################################################
tree.each_edge do |source, target, edge|
  edge_dist = tree.get_edge_distance_string(edge)
  lifestyle = edge_dist_cats.include?(edge_dist) ? edge_dist_cats[edge_dist] : 'X'
  if target.isTip?(tree)
    node_str = target.name
  else
    node_str = tree.tips(target).map{|i|i.name.gsub(' ', '_')}.sort.join('|')
  end
  puts [node_str, lifestyle].join("\t")
end


