#! /usr/bin/env ruby


#################################################################
require 'getoptlong'

require 'Dir'


#################################################################
trait_file = File.join(ENV["ASR"], 'mcmc', 'species.trait') if ENV.include?('ASR')

DIR = File.dirname($0)
CREATE_MULTISTATE_CTRL = File.join(DIR, 'createMultistateCtrl.rb')


#################################################################
class Fossil
  attr_accessor :name, :taxa, :states
  def initialize(name)
    @name = name
  end
end


#################################################################
infile = nil
mode = nil
mode_argu = nil
outdir = nil
cmd_file = nil
is_force = false
is_tolerate = false
is_cover = true

cmd_lines_str = ''
fossils = Hash.new
force_str = ''
tol_str = ''


#################################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['--mode', GetoptLong::REQUIRED_ARGUMENT],
  ['--mode_argu', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--trait_file', GetoptLong::REQUIRED_ARGUMENT],
  ['--cmd_file', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
  ['--tolerate', GetoptLong::NO_ARGUMENT],
  ['--no_c', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when /^-i$/
      infile = value
    when /^--mode$/
      mode = value
    when /^--mode_argu$/
      mode_argu = value
    when /^--outdir$/
      outdir = value
    when /^--trait_file$/
      trait_file = File.expand_path(value)
    when /^--cmd_file$/
      cmd_file = value
    when /^--force$/
      is_force = true
    when /^--tolerate$/
      is_tolerate = true
    when /^--no_c$/
      is_cover = false
  end
end


#################################################################
if is_force
  force_str = '--force'
end

if is_tolerate
  tol_str = '--tolerate'
end

if not cmd_file.nil?
  in_fh = File.open(cmd_file, 'r')
  lines = in_fh.readlines
  cmd_lines_str = lines.join('')
  in_fh.close
end


#################################################################
in_fh = File.open(infile, 'r')
in_fh.each_line do |line|
  line.chomp!
  next if line =~ /^$/
  next if line =~ /^#/
  line_arr = line.split("\t")
  name = line_arr[0]
  taxa = line_arr[1,2]
  states = line_arr[3, line_arr.size]
  fossil = Fossil.new(name)
  fossil.taxa = taxa
  fossil.states = states
  fossils[name] = fossil
end
in_fh.close


fossils.each_pair do |name, fossil|
  fossil.states.each do |state|
    outdir2 = File.join(outdir, name, state)
    if Dir.exists?(outdir2) and not is_cover
      next
    end
    #mkdir_with_force(outdir2, is_force, is_tolerate)
    add_cmds = Array.new
    add_cmds << cmd_lines_str
    add_cmds << ['AddTag', name, fossil.taxa].flatten.join(' ')
    add_cmds << ['AddMRCA', name, name].flatten.join(' ')
    add_cmds << ['fossil', name+'_fossil', name, state].flatten.join(' ')
    add_cmds << mode_argu
    add_cmd_str = add_cmds.map{|i|'--add_cmd ' + %w[' '].join(i)}.join(' ')
    `ruby #{CREATE_MULTISTATE_CTRL} --mode #{mode} --outdir #{outdir2} #{add_cmd_str} #{force_str} #{tol_str}`
    `cd #{outdir2}; ln -s #{trait_file} 2>/dev/null`
  end
end


