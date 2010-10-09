module RDF
  class Statement
    PLACEHOLDERS = (p = [:aaa, :bbb, :ccc, :ddd, :uuu, :vvv, :xxx, :yyy, :zzz]) + p.collect {|pl| RDF::Literal.new(pl)}  + p.collect {|pl| RDF::Node.new(pl)}
    
    #TODO: consider moving these methods into the RDF gem instead of reopening RDF::Statement here
    def with_substitutions(assignment_hash)
      return self unless assignment_hash
      statement_hash = to_hash
      [:subject, :object, :predicate].each { |place_in_statement|
        bound_variables, variable = assignment_hash.keys, statement_hash[place_in_statement]
        statement_hash[place_in_statement] = assignment_hash[variable] if bound_variables.collect(&:to_s).include?(variable.to_s)
        #TODO: fix node equality so I don't need to use to_s above
        }
      Statement.new(statement_hash)
    end
  
    def generality
      to_hash.values.select {|k| PLACEHOLDERS.include? k}.size
    end
    
    def has_placeholder?
      to_hash.values.detect {|k| PLACEHOLDERS.include? k}
    end
    
    def specificity
      3-generality
    end
  end
end

module RDFS
  ##
  # An RDFS entailment rule.
  class Rule
    include RDF

    PLACEHOLDERS = (p = [:aaa, :bbb, :ccc, :ddd, :uuu, :vvv, :xxx, :yyy, :zzz]) + p.collect {|pl| RDF::Literal.new(pl)}  + p.collect {|pl| RDF::Node.new(pl)}
    
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

    
    def match(statement1, statement2=nil, noisy = false)
      statements = [statement1, statement2].compact      
      
      return false unless antecedents.size == statements.size
      if antecedents.size == 1
        return false unless (@subs = self.class.unitary_match(antecedents.first, statements.first))
        return Rule.substitute(consequents, @subs)
        
      elsif (implied_assignments = Rule.unitary_match(antecedents_ordered_by_decreasing_specificity.first, statements.first))
        q = Rule.unitary_match(antecedents_ordered_by_decreasing_specificity.last.with_substitutions(implied_assignments), 
                               statements.last.with_substitutions(implied_assignments))
        assignments = q ? q.merge(implied_assignments) : q
        return Rule.substitute(consequents, assignments)
      elsif implied_assignments = Rule.unitary_match(antecedents_ordered_by_decreasing_specificity.first, statements.last)
        q = Rule.unitary_match(antecedents_ordered_by_decreasing_specificity.last.with_substitutions(implied_assignments), 
                               statements.first.with_substitutions(implied_assignments))
        assignments = q ? q.merge(implied_assignments) : q
        return Rule.substitute(consequents, assignments)
      else
        return false
      end
    end
    alias_method :[], :match
  
  
    #returns either false or the assignment hash of the match 
    def self.unitary_match(antecedent, statement)
      a, s = antecedent.to_hash, statement.to_hash
      #may need to exclude context
      bound = {}
      a.values.zip(s.values) {|antecedent_value, statement_value| 
        if PLACEHOLDERS.include?(antecedent_value) and !bound[antecedent_value]
          bound[antecedent_value] = statement_value
        elsif PLACEHOLDERS.include?(antecedent_value) and bound[antecedent_value]
          return false unless bound[antecedent_value] == statement_value
        else
          return false unless antecedent_value == statement_value
        end
        }
      return bound
    end

    def antecedents_ordered_by_decreasing_specificity
      a ||= antecedents.sort_by(&:generality)
    end
  
    def self.substitute(consequents, assignment_hash)
      return nil if assignment_hash.nil?
      c = consequents.collect{|c| c.with_substitutions(assignment_hash)}
      return c.detect(&:has_placeholder?) ? false : c
      
      #perhaps add an integrity check to Rule to make sure that the consequents are fully substituted by the antecedents
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