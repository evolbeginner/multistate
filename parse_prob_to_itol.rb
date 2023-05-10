#! /usr/bin/env ruby


################################################################
require 'getoptlong'
require 'descriptive_statistics'

require 'util'


################################################################
#trait2color = {'V'=>'green','F'=>'red','M'=>'orange','f'=>'blue'}
COLORS = %w[red blue purple red yellow]

SEP = ' '


################################################################
infile = nil
type = 'bc'
#trait2color = {'M'=>'red','N'=>'blue'}
traits_file = nil
trait2color = Hash.new

node2taxa = Hash.new{|h,k|h[k]=[]}
index2node = Hash.new
node2trait2prob = Hash.new{|h1,k1|h1[k1]=Hash.new{|h2,k2|h2[k2]=[]}}


################################################################
def bcPrint()
  template_file = File.expand_path("~/project/Rhizobiales/scripts/iTOL/template/branchColor")
  system("cat #{template_file}")
end


def pieChartPrint(trait2color:)
  template_file = File.expand_path("~/project/Rhizobiales/scripts/iTOL/template/pieChart")
  system("cat #{template_file}")
  puts ["DATASET_LABEL", "pie_chart"].flatten.join(SEP)
  puts ["FIELD_LABELS", trait2color.keys.sort].flatten.join(SEP)
  puts ["FIELD_COLORS", trait2color.sort_by{|k,v|k}.to_h.values].flatten.join(SEP)
  puts ["MAXIMUM_SIZE", 20].join(SEP)
  puts "DATA"
end


def get_trait2color(infile, h)
  trait2color = Hash.new
  traits = readTbl(infile)[1].keys.map{|i|i.split('')}.flatten.uniq
  traits.select!{|i|i!='-'}
  traits.sort.zip(COLORS).each do |trait, color|
    trait2color[trait] = color
  end
  trait2color.merge!(h)
  return(trait2color)
end


################################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['-t', '--type', GetoptLong::REQUIRED_ARGUMENT],
  ['--traits', GetoptLong::REQUIRED_ARGUMENT],
  ['--trait2color', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
    when '-t', '--type'
      type = value
    when '--traits'
      traits_file = value
    when '--trait2color'
      t, c = value.split(':')
      trait2color[t] = c
  end
end


trait2color = get_trait2color(traits_file, trait2color)


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
  elsif line =~ /^Tree No\tLh/ or line =~ /^(\d+|Iteration)\t/
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
        node2trait2prob[node_name][trait] << k
      end
    end
  end

end


################################################################
if type == 'bc'
  bcPrint()
elsif type == 'pie'
  pieChartPrint(trait2color:trait2color)
end


node2trait2prob.each_pair do |node_name, v1|
  node_str = node2taxa[node_name].join('|')
  if type == 'bc'
    trait, prob = v1.sort_by{|trait, probs|probs.mean}.reverse[0]
    color = trait2color.include?(trait) ? trait2color[trait] : 'grey'
    puts [node_str, 'branch', color, 'normal', 1].flatten.join(SEP)
  elsif type == 'pie'
    trait2prob = v1.sort_by{|trait, probs|trait}
    puts [node_str, 1, 0.1, trait2prob.map{|trait,probs|probs.mean}].flatten.join(SEP)
  end
end


