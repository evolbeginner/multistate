#! /usr/bin/env ruby


#################################################################
require 'getoptlong'
require 'parallel'

require 'Dir'
require 'util'


#################################################################
SORTED_TYPES = %w[P(F) P(V) P(f) P(M)]

indir = nil
outdir = nil
is_force = false

infiles = Array.new
node2prop = Hash.new{|h,k|h[k]={}}


#################################################################
opts = GetoptLong.new(
  ['--indir', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '--indir'
      indir = value
    when '--outdir'
      outdir = value
    when '--force'
      is_force = true
  end
end


#################################################################
infiles = read_infiles(indir)

infiles.each do |infile|
  c = getCorename(infile)
  node, type = c.split('_')
  in_fh = File.open(infile, 'r')
  lines = in_fh.readlines
  prop = lines.map{|i|i.to_f}.reduce(:+)/lines.size
  in_fh.close
  node2prop[node][type] = prop
end


#################################################################
mkdir_with_force(outdir, is_force) unless outdir.nil?

node2prop.each_pair do |node, v|
  puts node + "\t" + v.sort_by{|type, prop| SORTED_TYPES.index(type) }.map{|type, prop| prop}.join("\t")
  if not outdir.nil?
    outfile = File.join(outdir, node)
    out_fh = File.open(outfile, 'w')
    out_fh.puts v.sort_by{|type, prop| SORTED_TYPES.index(type) }.map{|type, prop| prop}.join("\t")
    out_fh.close
  end
end


