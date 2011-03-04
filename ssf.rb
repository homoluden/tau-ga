#encoding: utf-8
require_relative 'mtx'

class SSF
  attr_reader :a, :b, :c, :d, :k
  def initialize(a,b,c,d,ts,k)
		@a,@b,@c,@d,@ts,@t,@k = a,b,c,d,ts,0.0,k
		@x = NMatrix.float(@a.sizes[0],1)
		@order = @a.sizes[1]
	end
  def reset
    n = @x.sizes[1]
    n.times{|i| @x[0,i] = 0.0 }
  end
  #
  # Executes 1-step iteration of discrete SS-Model<br>
  # <b>+u+</b> (float) - input.<br>
  # <b>+xn+</b> (float) - dynamic process noise (State Vector addictive noise).<br>
  # <b>+fn+</b> (float) - measurement noise (Output Signal addictive noise).<br>
  # <b>+return+</b> (float) - noise affected output signal
	def step(u)
		tx 	= @a*@x + @b*u
    f = @c*@x
    @x = tx.clone
		@t += @ts
    return (f*@k)[0,0]
	end
  
  def SSF.align_num_denum(num,denum)
    d = denum.length - num.length
    if  d >= 0 then
	    num = num.reverse
	    d.downto(1) {
		    num << 0.0
	    }
	    num = num.reverse
    else
	    d.upto(-1) {
		    denum << 0.0
	    }
    end
    return num.length,num,denum
  end

  #
  # Creates "State-Space" model in discrete time
  # from <b>+num+</b> and <b>+denum+</b> of transfer function in <b>continous</b> time<br>
  # <b>+num+</b> - transfer function numerator.<br>
  # <b>+denum+</b> - transfer function denominator.<br>
  # <b>+k+</b> - desired gain of created SS-Model.<br>
  # <b>+ts+</b> - time sample (1/ts = Sampling Frequency).<br>
  def SSF.tf2ssd(num,denum,k,ts)
    n,num,denum = SSF::align_num_denum(num,denum)
    a = []
    b = []
    c = []
    (0).upto(n-3) {
	    |i|
	    ta = NArray.float(n-1)
	    ta[i+1] = 1.0
	    a << ta.to_a
	    b << [0.0]
    }
    ta = []
    (n-1).downto(1) {
	    |i|
	    ta << -denum[i]/denum[0]
    }
    a << ta
    b << [1.0/denum[0]]
    d = num[0]/denum[0]

    c = NMatrix.float(n-1,1)
    (n-1).downto(1) {
	    |i|
	    c[i-1,0] = d*(-denum[i]) + num[i]
    }

    am = NMatrix.rows(a)
    bm = NMatrix.rows(b)
    e =  NMatrix.float(n-1,n-1).unit
    f = e + am*ts + am**2*ts**2/2 + am**3*ts**3/3
    r = (e*ts + am*ts**2/2 + am**2*ts**3/3)*bm
    ssf = SSF.new(f,r,c,d,ts,k*denum.last/num.last)
    ssf
  end
end
