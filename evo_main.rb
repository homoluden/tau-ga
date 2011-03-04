require "yaml"
require "logger"
require "rubygems"
require "active_support"

class Evolution
  attr_reader :generations, :p_combination, :p_mutation, :best_chromosome, :best_fitness
  
  # Must be initialized with a Array of chromosomes
  # To be a chomosome the object must implement the next methods:
  #  - fitness
  #  - recombine
  #  - mutate
  #  Accepts the next properties:
  #   - extra_generations: adds given array of generations to the GeneticAlgorithm's own array of generations.
  #   - p_combination: probability of combiantion ( by default 0.2 )
  #   - p_mutation: probability of mutation ( by default 0.01 )
  #   - max_population: maximum number of individuals that are allowed to form a generation.
  #   - logger: logger to write messages if given.
  def initialize(in_pop, prop = {})    
    @generations = [in_pop]
    @generations += prop[:extra_generations] if prop[:extra_generations]
    @p_combination = prop[:p_combination] || 0.2
    @p_mutation = prop[:p_mutation] || 0.01
    @max_population =  prop[:max_population]
    @logger = prop[:logger] if prop[:logger]
  end


# HELPER METHODS

  # Returns the number of generations that are in the GeneticAlgorithm object.
  def num_generations
    @generations.size - 1
  end

  # Returns an array with the best fitted individuals for given
  # generation number ( by default from last generation ).
  def best_fit(num_generation = -1)
    raise "Generation not generated still num generations = #{self.num_generations}" if num_generation > self.num_generations
    generation = @generations[num_generation]
    @best_fitness = 0.0
    generation.collect { |chromosome|
      if chromosome
        fit = chromosome.fitness
        if fit.finite? && @best_fitness < fit
          @best_fitness = fit
          @best_chromosome = chromosome
        end
      end
    }
    [@best_chromosome, @best_fitness]
  end
  
  # Returns the mean of the fitness for given
  # generation number ( by default from last generation ).
  def mean_fitness(num = -1)
    raise "Generation not generated still num generations = #{self.num_generations}" if num > self.num_generations
    num = self.num_generations if num == -1
    sum_fitness = 0
    @generations[num].each { |chromosome| sum_fitness += chromosome.fitness if chromosome.fitness.finite? }
    sum_fitness.to_f / @generations[num].size.to_f
  end

  # Returns a GeneticAlgorithm object with the generations
  # loaded from given files and with properties prop.
  # Files must contain the chromosomes in YAML format.
  def self.populate_from_files(a_filenames, prop = {})
    a_filenames = [a_filenames] if a_filenames.class == String
    
    loaded_generations = a_filenames.collect { |filename| YAML.load(File.open(filename, "r")) }
    prop[:extra_generations] = loaded_generations[1..-1] if loaded_generations.size > 1
    return GeneticAlgorithm.new(loaded_generations[0], prop)
  end

  # Saves into filename and in yaml format the generation that matchs with given
  # generation number ( by default from last generation ).
  def save_generation(filename, num_generation = -1)
    f = File.new(filename, "w")
    f.write(self.generations[num_generation].to_yaml)
    f.close    
  end

# EVOLUTION METHODS

  # Evolves the actual generation num_steps steps (1 by default).
  def evolve(num_steps = 1)
    num_steps.times do
      @generations << evaluation(@generations[-1])
      selection!
      recombination! 
      mutation!
    end
  end
  
  # Prepares given generation for evaluation ( evaluates its fitness ).
  def evaluation(g)
    @logger.debug "Evaluation " + g.size.to_s + " chromosomes." if @logger
    i = 0
    g.collect do |chromosome|
      i += 1
      @logger.debug "Evaluating chromosome #{i}:" if @logger
      @logger.debug "#{chromosome.stats.join("\n")}" if @logger
      chromosome.fitness
      chromosome
    end
  end

  # Selects population to survive and recombine
  def selection(g)
    g_tmp = remainder_stochastic_sampling(g)
    g_tmp = g_tmp.sort_by {|i| -i.fitness }[0..(@max_population-1)] if @max_population && (g_tmp.size > @max_population)
    g_tmp
  end
  def selection!; @generations[-1] = selection(@generations[-1]); end

  # Recombines population  
  def recombination(g)
    @logger.debug "Recombination " + g.size.to_s + " chromosomes." if @logger
    new_generation = g.dup.shuffle!
    @logger.debug "Shuffled!" if @logger
    new_childs = []
    new_generation.in_groups_of(2) do |chromosome1, chromosome2|
      next if chromosome2.nil?
      if rand > (1 - @p_combination)
        @logger.debug "Recombining" if @logger
        new_childs += chromosome1.recombine(chromosome2)
      end
    end
    new_generation + new_childs    
  end

  def recombination!; @generations[-1] = recombination(@generations[-1]); end

  # Mutates population
  def mutation(g)
    r = Random.new
    @logger.debug "Mutation " + g.size.to_s + " chromosomes." if @logger  
    new_generation = g.dup
    new_generation.each do |chromosome|
      if r.rand(1.0) > (1 - @p_mutation)
        @logger.debug "Mutate" if @logger
        chromosome.mutate 
      end
    end
  end
  def mutation!; @generations[-1] = mutation(@generations[-1]); end
  
  # Remainder Stochastic Sampling algorithm for selection.
  def remainder_stochastic_sampling(g)
    r = Random.new
    new_generation = []
    g.each do |chromosome|
      num_rep = 0
      if chromosome.fitness > 0
        num_rep += (chromosome.fitness.to_f/(self.mean_fitness+@@eps)).to_i
        num_rep += 1 if r.rand(1.0) > (1 - (chromosome.fitness/self.mean_fitness)%1)
      end
      new_generation = new_generation + ([chromosome] * num_rep)
    end
    new_generation
  end

end