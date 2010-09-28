module RDFS
  ##
  # An RDFS entailment rule.
  class Rule
    include RDF

    PLACEHOLDERS = (p = [:aaa, :bbb, :ccc, :ddd, :uuu, :vvv, :xxx, :yyy, :zzz]) + p.collect {|pl| RDF::Literal.new(pl)} + p.collect {|pl| RDF::Node.new(pl)}
    
    # @return [Array<Statement>]
    attr_reader :antecedents

    # @return [Hash{Symbol => Class}]
    attr_reader :constraints

    # @return [Array<Statement>]
    attr_reader :consequents

    ##
    # @option options [Array<Statement>]      :antecedents ([])
    # @option options [Hash{Symbol => Class}] :constraints ({})
    # @option options [Array<Statement>]      :consequents ([])
    # @yield  [rule]
    # @yieldparam [Rule]
    def initialize(options = {}, &block)
      @antecedents = (@@antecedents[self.class] || []).concat(options[:antecedents] || [])
      @constraints = (@@constraints[self.class] || {}).merge( options[:constraints] || {})
      @consequents = (@@consequents[self.class] || []).concat(options[:consequents] || [])

      if block_given?
        case block.arity
          when 1 then block.call(self)
          else instance_eval(&block)
        end
      end
    end
    
    
    ##
    # Evaluates whether a rule pattern matches a set of statements.
    #
    # @param  Statement statement1
    # @param  Statement statement2
    #
    # All of the RDFS entailment rules are either pairwise or unitary on antecedents,
    # so Rule#match takes exactly one or two statements.
    # 
    # @return [Array<Statement>],  :consequents ([]) or nil
    
    def unitary_match?(antecedent, statement)
      #raise [antecedent.to_hash.keys - [:context]].inspect
      [antecedent.to_hash.keys - [:context]].flatten.collect {|place_in_statement|
        if PLACEHOLDERS.include? antecedent[place_in_statement]
          statement.to_hash[place_in_statement] == antecedent.to_hash[place_in_statement]
        else
          statement.to_hash[place_in_statement]
        end
      }.inject(true) { |acc, e| acc and e }
    end
    
    def match(statement1, statement2=nil, noisy = false)
      #first make sure the number of antecedents match the number of arguments
      if (ss = [statement1, statement2].compact.size) != @antecedents.size
        if noisy
          return [nil, "antecedent size (#{@antecedents.size}) doesn't match the arguments size #{ss}"]
        else
          return [nil, 'wtf']
        end
      end
      
      if @antecedents.size == 1
        first_statement = statement1
        first_antecedent = @antecedents.first
        if unitary_match?(first_antecedent, first_statement)
          return consequents.collect {|c| consequent_with_mappings_subbed_in(first_antecedent, c, first_statement)}
        else
          return nil
        end
      else
        return nil
        #only handles single antecedent and statement matches
      end
    end
    alias_method :[], :match
    
    def mappings_from(antecedents)
      binding = {:subject => statement.subject, :predicate => statement.predicate, :object => statement.object}
    end
    
    def consequent_with_mappings_subbed_in(antecedent, consequent, statement)
      #antecedent_slots = {:subject => antecedent.subject, :predicate => antecedent.predicate, :object => antecedent.object}
      slots = {:subject => consequent.subject, :predicate => consequent.predicate, :object => consequent.object}
      binding = {:subject => statement.subject, :predicate => statement.predicate, :object => statement.object}
      final_statement = {}
      [:subject, :predicate, :object].each {|p|
        consequent_value = slots[p]
        statement_value = binding[p]        
        # final_statement[p] = PLACEHOLDERS.include?(consequent_value) ? statement_value : consequent_value
        final_statement[p] = PLACEHOLDERS.include?(consequent_value) ? binding[place_from_antecedent(consequent_value, antecedent)] : consequent_value

      }
      final_statement = Statement.new final_statement
      #raise final_statement.subject.class.inspect
    end
    
    
    def place_from_antecedent(test, antecedent)
      antecedent.to_hash.each {|k,v| return k if v == test}
    end
    
    
    
    def consequents_from(assignments)
      consequent_patterns = consequents.collect(&:to_hash)
      output = []
      consequent_patterns.each_with_index {|c,i|
        c.each {|k,v| 
          (c[k] = assignments[v]; output << RDF::Statement.new(c)) if PLACEHOLDERS.include?(v) }        
      }
      return output
    end

    ##
    # Defines an antecedent for this rule.
    #
    # @param  [Symbol, URI] s
    # @param  [Symbol, URI] p
    # @param  [Symbol, URI] o
    # @return [void]
    def antecedent(s, p, o)
      @antecedents << RDF::Statement.new(s, p, o)
    end

    ##
    # Defines a type constraint for this rule.
    #
    # @param  [Hash{Symbol => Class}] types
    # @return [void]
    def constraint(types = {})
      @constraints.merge!(types)
    end

    ##
    # Defines the consequent of this rule.
    #
    # @param  [Symbol, URI] s
    # @param  [Symbol, URI] p
    # @param  [Symbol, URI] o
    # @return [void]
    def consequent(s, p, o)
      @consequents << RDF::Statement.new(s, p, o)
    end

    protected
      @@antecedents = {} # @private
      @@constraints = {} # @private
      @@consequents = {} # @private

      ##
      # @private
      def self.inherited(subclass)
        @@antecedents[subclass] = []
        @@constraints[subclass] = {}
        @@consequents[subclass] = []
      end

      ##
      # Defines an antecedent for this rule class.
      #
      # @param  [Symbol, URI] s
      # @param  [Symbol, URI] p
      # @param  [Symbol, URI] o
      # @return [void]
      def self.antecedent(s, p, o)
        @@antecedents[self] << RDF::Statement.new(s, p, o)
      end

      ##
      # Defines a type constraint for this rule class.
      #
      # @param  [Hash{Symbol => Class}] types
      # @return [void]
      def self.constraint(types = {})
        @@constraints[self].merge!(types)
      end

      ##
      # Defines the consequent of this rule class.
      #
      # @param  [Symbol, URI] s
      # @param  [Symbol, URI] p
      # @param  [Symbol, URI] o
      # @return [void]
      def self.consequent(s, p, o)
        @@consequents[self] << RDF::Statement.new(s, p, o)
      end

  end
end
