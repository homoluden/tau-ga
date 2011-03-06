#encoding: utf-8
require_relative 'array_helper'
require_relative 'evo_main'
require_relative 'ssf'
require_relative 'plotter'

@@eps = 1e-4
@@ts = 0.1
@@test_input = 1.0
@@test_filter = SSF::tf2ssd([1.5, 1.0], [0.75, 0.35, 1.1], 1.0, @@ts)
def step_response_deviation(filter)
  x, test_y,y = step_response(filter)
  av_err = 0.0
  100.times {|i|
    err = test_y[i] - y[i]
    av_err += err*err
  }
  Math.sqrt(av_err / 99)
end
def step_response(filter)
  @@test_filter.reset
  filter.reset
  x = Array.new(100) {|i| i*@@ts}
  test_y = Array.new(100) {@@test_filter.step(@@test_input)}
  y = Array.new(100) {filter.step(@@test_input)}
  return x,test_y,y
end

class TFIndivid
    attr_reader :filter, :fitness, :dna, :num_len, :denom_len
    def initialize(num,denom,k=1.0,ts=@@ts)
      @num_len,@denom_len,@filter = num.length,denom.length,SSF::tf2ssd(num, denom, k, ts)
      @fitness = 1/(step_response_deviation(@filter)+@@eps)
      @fitness = 0.0 if @fitness.infinite?

      @dna = num + denom + [k] + [ts]
      self
    end
    def integrity_ok?(dna)
      return dna.length == @num_len + @denom_len + 2
    end
    def TFIndivid.flat_crossover(par1, par2)
      r = Random.new
      child = []
      par1.size.times { |i|
        if par1[i]>par2[i]
          child << r.rand(par2[i]..par1[i])
        else
          child << r.rand(par1[i]..par2[i])
        end
      }
      child
    end
    def recombine(other)
      child = TFIndivid::flat_crossover(self.dna, other.dna)
      res = self.integrity_ok?(child) ? TFIndivid.new(child[0..@num_len-1], child[@num_len..-3], child[-2], child[-1]) : []
      [res]
    end

    def mutate
      rnd = Random.new
      mutate_point = rnd.rand(@dna.size-1)
      @dna[mutate_point] *= rnd.rand(1.0)
    end

end
def create_population(num_len = 2, denom_len = 3, max_num_initial = 1e5, pop_size = 15)
  rnd = Random.new
  population = []
  pop_size.times {
    num, denom, k = [],[],rnd.rand(@@eps..2.0)
    num_len.times { num << rnd.rand(max_num_initial) }
    denom_len.times {denom << rnd.rand(max_num_initial)}
    population << TFIndivid.new(num, denom, k, @@ts)
  }
  population
end
evo = Evolution.new(create_population(2, 3, 1e1, 350), {:max_population => 500, :p_mutation => 0.0025 })
50.times { |i|
  evo.evolve
  best_fit = evo.best_fit

  puts "Iteration: #{i+1}",
       "Population size: #{evo.generations[-1].size}",
       "best Individ: #{best_fit[0].dna.inspect}",
       "best fitness: #{best_fit[1]}",
       "mean fitness: #{evo.mean_fitness}"
  fitness_sum = 0.0
  evo.generations[-1].each { |chromosome|
    fitness_sum += chromosome.fitness
  }
  
  tmp = fitness_sum.to_f / evo.generations[-1].size.to_f
  puts "mean fitness recalc #{tmp}"
  
  puts "*"*30
}
x,test_y,y = step_response(evo.best_fit[0].filter)
SSPlotter.draw_multy_dataset("Step response", "Time, sec.", "Response, V", 'lines', x, [test_y,y])