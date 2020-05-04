#! /usr/bin/env ruby


################################################################
require 'getoptlong'


################################################################
TRAIT2COLOR = {'V'=>'green','F'=>'red','M'=>'orange','f'=>'blue'}
TEMPLATE_FILE = File.expand_path("~/project/Rhizobiales/scripts/iTOL/template/branchColor")


################################################################
infile = nil

node2taxa = Hash.new{|h,k|h[k]=[]}
index2node = Hash.new
node2trait2prob = Hash.new{|h1,k1|h1[k1]={}}


################################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
  end
end


################################################################
lines = File.readlines(infile).map{|i|i.chomp!}

is_node = false
is_prob = false

lines.each do |line|
  line_arr = line.split("\t")    

  if is_node and line !~ /^\tnode\d+/
    is_node = false
  end

  if line =~ /^Tags:/
    is_node = true
    #Tags:	654
	    #node1	2	Meganema_perideroedes_DSM_15528 Terasakiella_pusilla_DSM_6293 
  elsif line =~ /^Tree No\tLh/
    is_prob = true
  end

  if is_node
    node, taxon_str = line_arr.values_at(1,3)
    next if taxon_str.nil?
    taxa = taxon_str.split(' ').values_at(0,1)
    node2taxa[node] = taxa
  elsif is_prob
    if index2node.empty?
      line_arr.each_with_index do |k, index|
        if k =~ /^(Root|node)/
          index2node[index] = k
        end
      end
    else
      line_arr.each_with_index do |k, index|
        next unless index2node.include?(index)
        node = index2node[index]
        node_name, trait = node.split(' ')
        trait =~ /P\((.+)\)/
        trait = $1
        node2trait2prob[node_name][trait] = k
      end
    end
  end

end


################################################################
system("cat #{TEMPLATE_FILE}")


node2trait2prob.each_pair do |node_name, v1|
  trait, prob = v1.sort_by{|trait, prob|prob}.reverse[0]
  node_str = node2taxa[node_name].join('|')
  color = TRAIT2COLOR.include?(trait) ? TRAIT2COLOR[trait] : 'grey'
  puts [node_str, 'branch', color, 'normal', 1].flatten.join(' ')
end


