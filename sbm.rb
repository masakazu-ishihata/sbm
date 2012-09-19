#!/usr/bin/env ruby

################################################################################
# default
################################################################################
@@debug = false
@ifile = "test.dat"
@ofile = "test.out"
@a = 1
@b = 1
@n = 100
@N = 3
@seed = rand(1000)

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
  opts.on("-i [string]", "input file"){ |f|
    @ifile = f
  }
  opts.on("-o [string]", "output file"){ |f|
    @ofile = f
  }
  opts.on("-n [int]", "# sampling"){ |f|
    @n = f.to_i
  }
  opts.on("-N [int]", "# clasters"){ |f|
    @N = f.to_i
  }
  opts.on("-a [double]", "alpha"){ |f|
    @a = f.to_f
  }
  opts.on("-b [double]", "beta"){ |f|
    @b = f.to_f
  }
  opts.on("-s [int]", "seed"){ |f|
    @seed = f.to_i
  }
  opts.on("--debug", "debug mode"){
    @@debug = true
  }
  # parse
  opts.parse!(ARGV)
}

################################################################################
# Array
################################################################################
class Array
  #### sum ####
  def sum
    s = 0
    for i in 0..self.size-1
      s += self[i]
    end
    s
  end

  #### product ####
  def prod
    p = 1
    for i in 0..self.size-1
      p *= self[i]
    end
    p
  end

  #### sample ####
  def sample
    z = self.sum
    r = rand * z.to_f
    s = 0
    for i in 0..self.size-1
      s += self[i]
      return i if r < s
    end
    return -1
  end
end

################################################################################
# Stochastic Block Model
################################################################################
class MySBM
  #### new ####
  def initialize(_file, _n)
    @a = 1             # \alpha
    @b = 1             # \beta
    @seed = rand(100)  # random seed

    srand(@seed)

    f = open(_file)

    # dimension
    @d = f.gets.to_i

    # # clasters
    @n = Array.new(@d){|i| _n}

    # # instances
    @m = Array.new(@d){|i| f.gets.to_i}

    # # values
    @v = f.gets.to_i + 1

    # initilize counts of \pi
    @c  = Array.new(@d){|d| Array.new(@m[d]){|m| rand(@n[d]) }}
    @Cp = Array.new(@d){|d| Array.new(@n[d]){|n| 0} }
    for d in 0..@d-1
      @c[d].each do |c|
        @Cp[d][c] += 1
      end
    end

    # initialize counts of \eta
    @Ce = Hash.new(nil) # @Ck[key][v] = count of \eta_{key,v}
    ckey = Array.new(@d){|d| 0}
    begin
      k = ckey.clone
      @Ce[k]    = Array.new(@v){|v| 0}
      @Ce[k][0] = Array.new(@d){|d| @Cp[d][ckey[d]]}.prod
    end while (ckey = succ_ckey(ckey)) != nil

    # initialize data matrix A
    @A = Hash.new(nil)
    vkey = Array.new(@d){|d| 0}
    begin
      k = vkey.clone
      @A[k] = 0
    end while (vkey = succ_vkey(vkey)) != nil

    # load data matrix A
    while line = f.gets
      a = line.split.map{|v| v.to_i}
      v = a.pop + 1

      # update data matrix
      vkey = a
      @A[vkey] = v

      # update count
      ckey = vkey2ckey(a)
      @Ce[ckey][0] -= 1
      @Ce[ckey][v] += 1
    end
  end

  ################################################################################
  # accessor
  ################################################################################
  #### reader ####
  attr_reader :d, :n, :m, :c, :Cp, :Ce

  #### setters ####
  def set_a(_a)
    @a = _a
  end
  def set_b(_b)
    @b = _b
  end
  def set_seed(_s)
    @seed = _s
    srand(@seed)

    # re-randomize
    for d in 0..@d-1
      for i in 0..@m[d]-1
        @c[d][i] = rand(@n[d])
      end
    end

    # re-count
    count
  end

  ################################################################################
  # count
  ################################################################################
  #### just count ####
  def count
    # init @Cp & @Ce
    for d in 0..@d-1
      for c in 0..@n[d]-1
        @Cp[d][c] = 0
      end
    end
    @Ce.clear

    # count @Cp
    for d in 0..@d-1
      for i in 0..@m[d]-1
        @Cp[d][ @c[d][i] ] += 1
      end
    end

    # count @Ce
    @A.keys.each do |vkey|
      ckey = vkey2ckey(vkey)
      @Ce[ckey] = Array.new(@v){|v| 0} if @Ce[ckey] == nil
      @Ce[ckey][ @A[vkey] ] += 1
    end
  end

  #### pull counts of c_i^d ####
  def pull(_d, _i)
    c = @c[_d][_i]

    # pull from @Cp
    @Cp[_d][c] -= 1

    # pull from @Ce
    vkey = Array.new(@d){|d| 0}
    vkey[_d] = _i
    begin
      ckey = vkey2ckey(vkey)
      @Ce[ckey][ @A[vkey] ] -= 1
    end while (vkey = succ_vkey_d(vkey, _d)) != nil

    @c[_d][_i] = nil
  end

  #### push counts of c_i^d = k ####
  def push(_d, _i, _k)
    abort("invalid push") if @c[_d][_i] != nil

    @c[_d][_i] = _k

    # push to @Cp
    @Cp[_d][_k] += 1

    # push to @Ce
    vkey = Array.new(@d){|d| 0}
    vkey[_d] = _i
    begin
      ckey = vkey2ckey(vkey)
      @Ce[ckey][ @A[vkey] ] += 1
    end while (vkey = succ_vkey_d(vkey, _d)) != nil
  end

  ################################################################################
  # class
  ################################################################################
  #### export classes ####
  def export_c
    c = Array.new(@d){|d| @c[d].clone }
  end

  #### import classes ####
  def import_c(_c)
    # substitute
    for d in 0..@d-1
      for i in 0..@m[d]-1
        @c[d][i] = _c[d][i]
      end
    end

    # count
    count
  end

  ################################################################################
  # about keys (patterns)
  ################################################################################
  #### ckey ####
  # normal successor
  def succ_ckey(_ckey)
    for d in 0..@d-1
      if _ckey[d] < @n[d]-1
        _ckey[d] += 1
        return _ckey
      else
        _ckey[d] = 0
      end
    end
    return nil
  end
  # successor with fixed point
  def succ_ckey_d(_ckey, _d)
    for d in 0..@d-1
      next if d == _d
      if _ckey[d] < @n[d]-1
        _ckey[d] += 1
        return _ckey
      else
        _ckey[d] = 0
      end
    end
    return nil
  end

  #### vkey ####
  #
  def vkey2ckey(_vkey)
    Array.new(@d){|d| @c[d][ _vkey[d] ]}
  end
  # normal successor
  def succ_vkey(_vkey)
    for d in 0..@d-1
      if _vkey[d] < @m[d]-1
        _vkey[d] += 1
        return _vkey
      else
        _vkey[d] = 0
      end
    end
    return nil
  end
  # successor with fixed point
  def succ_vkey_d(_vkey, _d)
    for d in 0..@d-1
      next if d == _d
      if _vkey[d] < @m[d]-1
        _vkey[d] += 1
        return _vkey
      else
        _vkey[d] = 0
      end
    end
    return nil
  end

  ################################################################################
  # sampling
  ################################################################################
  #### sample ####
  def sample
    for d in 0..@d-1
      for i in 0..@m[d]-1
        update(d, i)
      end
    end

    cal_log_ml
  end

  #### update c_i^d ####
  def update(_d, _i)
    d = cal_fcpd(_d, _i)
    k = d.sample

    puts "@c[#{_d}][#{_i}] = #{@c[_d][_i]} -> #{k} (#{d.map{|q| q/d.sum}.join(", ")})" if @@debug

    if @c[_d][_i] != k
      pull(_d, _i)
      push(_d, _i, k)
    end
  end

  #### cal full conditional probability distribution ####
  # p(c_i^d | c_{-i}^d, c^{-d}, a, b)
  def cal_fcpd(_d, _i)
    Array.new(@n[_d]){|k| cal_fcp(_d, _i, k) }
  end

  #### cal full conditonal probability ####
  # p(c_i^d = k | c_{-i}^d, c^{-d}, a, b)
  # \propto @Cp[d][k] * \pi_{key s.t. key[d] = k} Z(Ce+[key], b) / Z(Ce-[key], b)
  # Ce+[key] = count with c_i^d = k
  # Ce-[key] = count without c_i^d
  def cal_fcp(_d, _i, _k)
    old_c = @c[_d][_i]

    #### denomenator ####
    pull(_d, _i)
    de = 0.0
    ckey = Array.new(@d){|d| 0}
    ckey[_d] = _k
    begin
      de += cal_log_Z(@Ce[ckey], @b)
    end while (ckey = succ_ckey_d(ckey, _d)) != nil

    #### neumerator ####
    push(_d, _i, _k)
    nu = 0.0
    ckey = Array.new(@d){|d| 0}
    ckey[_d] = _k
    begin
      nu += cal_log_Z(@Ce[ckey], @b)
    end while (ckey = succ_ckey_d(ckey, _d)) != nil

    #### recover ####
    if old_c != _k
      pull(_d, _i)
      push(_d, _i, old_c)
    end

    #### p(k |~) ####
    Math::exp( Math::log(@Cp[_d][_k]) + nu - de )
  end

  #### cal z ####
  def cal_log_Z(_ary, _alpha)
    n = _ary.size

    nu = 0.0
    de = 0.0
    for i in 0..n-1
      nu += Math::lgamma(_ary[i] + _alpha)[0]
      de += _ary[i] + _alpha
    end
    de = Math::lgamma(de)[0]

    nu - de
  end

  #### cal log marginal likelihood ####
  def cal_log_ml
    lml = 0

    # log p(c^d | \alpha)
    for d in 0..@d-1
      lml += cal_log_Z(@c[d], @a)
    end

    # log p(A | c, \beta)
    @Ce.keys.each do |ckey|
      lml += cal_log_Z(@Ce[ckey], @b)
    end
    lml -= @Ce.size * cal_log_Z(Array.new(@v){|v| 0}, @b)

    lml
  end

  #### esitimate eta ####
  def cal_eta(ckey)
    d = Array.new(@v){|v| @Ce[ckey][v] + @b}
    s = d.sum
    d.map{|q| q / s.to_f }
  end

  ################################################################################
  # show
  ################################################################################
  def show_setting
    puts "a = #{@a}"
    puts "b = #{@b}"
    puts "n = [#{@n.join(", ")}]"
    puts "m = [#{@m.join(", ")}]"
    puts "s = #{@seed}"
  end

  def show
    puts "#### proparty ####"
    puts "Dim   = #{@d}"
    puts "Class = [#{@n.join(", ")}]"
    puts "Data  = [#{@m.join(", ")}]"

    # count of pi
    puts "#### Count of \\pi ####"
    for d in 0..@d-1
      for c in 0..@n[d]-1
        puts "[#{d}, #{c}] => #{@Cp[d][c]}"
      end
    end

    # count of eta
    puts "#### Counts of \\eta ####"
    @Ce.keys.sort.each do |key|
      puts "[#{key.join(", ")}] => [#{@Ce[key].join(", ")}]"
    end

    # class
    puts "#### clustering result ####"
    for d in 0..@d-1
      p @c[d]
    end
  end
end

################################################################################
# main
################################################################################
m = MySBM.new(@ifile, @N)
m.set_a(@a)
m.set_b(@b)
m.set_seed(@seed)

#### show setting ####
puts "--------------------------------------------------------------------------------"
m.show_setting
puts "--------------------------------------------------------------------------------"

#### collapsed gibbs sampling ####
best_lml = m.cal_log_ml
best_c   = m.export_c
for i in 1..@n
  t1 = Time.now
  lml = m.sample
  t2 = Time.now
  printf("%5d, %10.5e, %10.5e\n", i, lml, t2-t1)
  if best_lml < lml
    best_lml = lml
    best_c   = m.export_c
  end
end

#### result ####
m.import_c(best_c)
f = open(@ofile, "w")
f.puts "lp = #{m.cal_log_ml}"
for d in 0..m.d-1
  f.puts "z[#{d}] = {#{m.c[d].join(", ")}}"
end
m.Ce.keys.sort.each do |ckey|
  f.puts "{#{ckey.join(", ")}}, {#{m.cal_eta(ckey).join(", ")}}"
end
f.close
