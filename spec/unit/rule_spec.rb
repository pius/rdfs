require 'spec_helper'
require 'rdf'
require 'rdfs/rule'
include RDF
include RDFS::Semantics

describe ::RDF::Statement do
  it "should be able to substitute a mapping into itself" do
    statement = Statement.new(:aaa, :xxx, FOAF.person)
    mapping = {RDF::Node.new(:aaa) => 'rdf:friend', RDF::Node.new(:xxx) => 'rdf:knows'}
    a = statement.with_substitutions(mapping)
    a.should eql Statement.new('rdf:friend', 'rdf:knows', FOAF.person)
  end
  
  it "should know its specificity" do
    a1 = Statement.new(:aaa, RDFS.domain, :xxx)
    a2 = Statement.new(:uuu, :aaa, :yyy)
  
    [a1, a2].collect(&:specificity).should == [1,0]
    [a1, a2].sort_by(&:specificity).should == [a2,a1]
  end
  
end
  

describe ::RDFS::Rule do
  
  before(:each) do
    @rule1 = RDF1.new
    @statement1 = Statement.new('joe:shmoe', 'rdf:jerk', 'schmuck')
    @matching_statements_1 = [Statement.new('rdf:jerk', RDF.type, RDF.Property)]
    
    @rule2 = RDFS2.new
    @statement2 = Statement.new('rdf:annoys', RDFS.domain, FOAF.person)
    @statement3 = Statement.new('tom', 'rdf:annoys', 'jerry')
    @statement4 = Statement.new('tom', RDF.type, FOAF.person)
  end
  
  it "should know its antecedents" do
    @rule1.antecedents.should eql([Statement.new(:uuu, :aaa, :yyy)])
  end
  
  it "should know its consequents" do
    @rule1.consequents.should eql([Statement.new(:aaa, RDF.type, RDF.Property)])
  end
  
  it "should be able to substitute a mapping into consequents" do
    consequents = [Statement.new(:aaa, :xxx, FOAF.person)]
    mapping = {RDF::Node.new(:aaa) => 'rdf:friend', RDF::Node.new(:xxx) => 'rdf:knows'}
    a = ::RDFS::Rule.substitute(consequents, mapping)
    a.should eql [Statement.new('rdf:friend', 'rdf:knows', FOAF.person)]
  end
  
  it "should be able to do unitary matches" do
    antecedent = Statement.new :uuu, :aaa, :yyy
    @statement1 = Statement.new('joe:shmoe', 'rdf:jerk', 'schmuck')
    ::RDFS::Rule.unitary_match(antecedent, @statement1).should be_true
  end

  it "should not unitary match if non-placeholders are different" do
    a1 = Statement.new(:aaa, RDFS.domain, :xxx)
    s1 = Statement.new('rdf:annoys', RDFS.subPropertyOf, FOAF.person)
    ::RDFS::Rule.unitary_match(a1, s1).should be_false
  end

    
  context "should generate consequents from pairs of statements that match the antecedents" do
    
    it "with just one antecedent and one consequent" do
      @rule1[@statement1].should eql(@matching_statements_1)
      
      @rule_rdfs4a = RDFS4a.new
      @statements_matching_rule_rdfs4a = [Statement.new('rdf:annoys', RDF.type, RDFS.Resource)]
      @rule_rdfs4a[@statement2].should eql @statements_matching_rule_rdfs4a
    end
    
    it "matching should be commutative" do
      @rule2[@statement2,@statement3].should eql @rule2[@statement3,@statement2]
    end
    
    it "with multiple antecedents and one consequent" do  
      @rule2 = RDFS2.new
      @rule2[@statement2,@statement3].should eql([@statement4])
    end

    it "with multiple antecedents" do
      @rule2[@statement2,@statement3].should eql [Statement.new('tom', RDF.type, FOAF.person)]
      @rule2[@statement3,@statement2].should eql [Statement.new('tom', RDF.type, FOAF.person)]
    end

  end
    
  context "should not generate consequents from pairs of statements that don't match the antecedents" do
    it "with multiple antecedents" do
      @rule2 = RDFS2.new

      @statement2 = Statement.new('rdf:annoys', RDFS.domain, FOAF.person)
      d = Statement.new('foo', 'bar', 'baz')
      @rule2[@statement2,d].should be_false
    end
  end
end