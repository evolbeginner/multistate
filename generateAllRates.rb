#! /usr/bin/env ruby


#########################################################
require 'getoptlong'


#########################################################
features = Array.new

rates = Array.new


#########################################################
def get_forward_backward(features, rates)
  features.each do |f1|
    features.each do |f2|
      next if f1 == f2
      rates << [f1+f2, f2+f1].sort.join('-')
    end
  end
  return(rates)
end


def get_same_target(features, rates)
  features.each do |f1|
    features.each do |f2|
      next if f1 == f2
      features.each do |f3|
        next if f2 == f3 or f3 == f1
        rates << [f2+f1, f3+f1].sort.join('-')
      end
    end
  end
  return(rates)
end


#########################################################
opts = GetoptLong.new(
  ['-f', '--feature', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-f', '--feature'
      features << value.split(',')
  end
end


#########################################################
features.flatten!


#########################################################
rates = get_forward_backward(features, rates)

rates = get_same_target(features, rates)

rates.flatten!
rates.uniq!


#########################################################
puts rates.join(' ')


