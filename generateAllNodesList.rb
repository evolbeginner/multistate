#! /usr/bin/env ruby


############################################################################
$: << File.join(File.dirname($0), 'lib')


############################################################################
require 'getoptlong'
require 'bio'

require 'tree'


############################################################################
infile = nil


############################################################################
def getTwoTaxa4AllNodes(nodes, tag_name, node_name)
  rv_arr = Array.new
  node_str = nodes.map{|i|i.name.gsub(' ', '_')}.join("\t")
  rv_arr << ["AddTag", tag_name, node_str].join("\t")
  rv_arr << ["AddNode", node_name, tag_name].join("\t")
  return(rv_arr)
end


############################################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when /^-i$/
      infile = value
  end
end


############################################################################
tree = getTreeObjs(infile, 1).shift


tree.internal_nodes.each_with_index do |node, index|
  nodes = tree.tips(node)
  node_str = tree.twoTaxaNode(node).map{|i|i.name.gsub(' ', '_')}.join("\t")
  next if tree.twoTaxaNode(node).size == 1
  puts ['node'+(index+1).to_s, node_str].join("\t")
end


