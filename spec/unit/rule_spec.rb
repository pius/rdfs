require 'spec_helper'
require 'rdf'
require 'rdfs/rule'
include RDF
include RDFS::Semantics

describe ::RDFS::Rule do
  
  before(:each) do
    
    @rule1 = RDF1.new
    @statement1 = Statement.new('joe:shmoe', 'rdf:jerk', 'schmuck')
    @matching_statements_1 = [Statement.new('rdf:jerk', RDF.type, RDF.Property)]
    
    @rule2 = RDFS2.new
    @statement2 = Statement.new('rdf:jerk', RDFS.domain, FOAF.person)
    @dummy_statement2 = Statement.new('rdf:jerk', RDF.type, 'schmuck')
    @matching_statements_2 = [@statement1, @statement2]
    @dummy_statements_2 = [@statement1, @dummy_statement2]
    
    
  end
  
  it "should know its antecedents" do
    @rule1.antecedents.should eql([Statement.new(:uuu, :aaa, :yyy)])
  end
  
  it "should know its consequents" do
    @rule1.consequents.should eql([Statement.new(:aaa, RDF.type, RDF.Property)])
  end
  
  it "should be able to do unitary matches" do
     @rule1.unitary_match?(@rule1.antecedents.first, @statement1).should_not be_false
     @rule1.unitary_match?(@rule1.antecedents.first, @statement1).should_not be_nil
  end
  
  context "should generate consequents from pairs of statements that match the antecedents" do
    it "with just one antecedent" do
      @rule1[@statement1].should eql(@matching_statements_1)
    end
  #   
  #   # it "with multiple antecedents" do
  #   #   @rule2[*@matching_statements_2].should eql? [Statement.new('joe:shmoe', RDF.type, FOAF.person)]
  #   #   @rule2[*(@matching_statements_2.reverse)].should eql? [Statement.new('joe:shmoe', RDF.type, FOAF.person)]
  #   # end
  # end
  # 
  # context "should not generate consequents from pairs of statements that don't match the antecedents" do
  #   it "with multiple antecedents" do
  #     @rule2[*@dummy_statements_2].should eql? nil
  #     @rule2[*(@dummy_statements_2.reverse)].should eql? nil
  #   end
  end
  
  # context "rdfs7 transitivity via subProperties should work" do
  #   it "well" do
  #     class RDF3 < RDFS::Rule
  #       antecedent :aaa, RDFS.subPropertyOf, :bbb
  #       antecedent :uuu, :aaa, :yyy
  #       
  #       consequent :uuu, :bbb, :yyy
  #     end
  # 
  #     
  #     @rule1 = RDF3.new
  #     @statement1 = Statement.new('rdf:annoys', RDFS.subPropertyOf, 'rdf:angers')
  #     @matching_statements_1 = [@statement1]
  # 
  #     @statement2 = Statement.new('joe', 'rdf:annoys', 'pius')
  #     corpus = [@statement1, @statement2]
  #     @rule1[corpus].should eql? 'wtf'#[Statement.new('joe', 'rdf:angers', 'pius')]
  #   end
  # end
end