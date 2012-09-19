#!/usr/bin/env ruby

################################################################################
# default
################################################################################
@d = 2
@n = 3
@m = 30
@r = 1

################################################################################
# Arguments
################################################################################
require "optparse"
OptionParser.new { |opts|
  # options
  opts.on("-h","--help","Show this message") {
    puts opts
    exit
  }
  opts.on("-d [int]"){ |f|
    @d = f.to_i
  }
  opts.on("-n [int]"){ |f|
    @n = f.to_i
  }
  opts.on("-m [int]"){ |f|
    @m = f.to_i
  }
  opts.on("-r [int]"){ |f|
    @r = f.to_i
  }
  # parse
  opts.parse!(ARGV)
}

################################################################################
# Class
################################################################################
class MyTestData
  def initialize(_d, _n, _m, _r)
    @d = _d
    @n = _n
    @m = _m
    @r = _r
  end

  def generate
    #### header ####
    puts "#{@d}"
    for d in 0..@d-1
      puts "#{@m}"
    end
    puts "#{@r}"

    #### randomize clusters ####
    @c = Array.new(@d){|d| Array.new(@m){|i| rand(@n)} }

    #### randomize relations ####
    @R = Hash.new
    key = Array.new(@d){|d| 0}
    begin
      @R[key.clone] = rand(@r+1)
    end while (key = succ_key(key, @n)) != nil

    #### show data matrix ####
    key = Array.new(@d){|d| 0}
    begin
      ckey = Array.new(@d){|d| @c[d][ key[d] ]}
      puts "#{key.join(" ")} #{@R[ckey]-1}" if @R[ckey] > 0
    end while (key = succ_key(key, @m)) != nil
  end

  def succ_key(key, n)
    for d in 0..@d-1
      if key[d] < n-1
        key[d] += 1
        return key
      else
        key[d] = 0
      end
    end

    return nil
  end
end

################################################################################
# main
################################################################################
d = MyTestData.new(@d, @n, @m, @r)
d.generate
