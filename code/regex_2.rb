require 'pp'

Candidate = Struct.new(:prefix, :match, :suffix) do
  def take_suffix
    Candidate.new(prefix + match, suffix, "")
  end
end

class Matcher
  def call(candidates)
    check(candidates)
  end

  def |(other)
    Or.new(self, other)
  end

  def +(other)
    Then.new(self, other)
  end
end

class MatchString < Matcher
  def initialize(substr)
    @substr = substr
  end

  def check(candidates)
    candidates.map {|candidate|
      tokens = candidate.match.split(@substr, 2)
      if tokens.size == 2
        Candidate.new(
          tokens[0],
          @substr,
          tokens[1]
        )
      end
    }.reject(&:nil?)
  end
end

class Or < Matcher
  def initialize(lhs, rhs)
    @lhs = lhs
    @rhs = rhs
  end

  def check(candidates)
    Enumerator.new do |y|
      @lhs.call(candidates).each {|x| y.yield x }
      @rhs.call(candidates).each {|x| y.yield x }
    end
  end
end

class Then < Matcher
  def initialize(lhs, rhs)
    @lhs = lhs
    @rhs = rhs
  end

  def check(candidates)
    Enumerator.new do |y|
      @lhs.call(candidates).each do |candidate|
        @rhs.call([candidate.take_suffix].lazy).each {|z|
          y.yield merge(candidate, z)
        }
      end
    end
  end

  private

  def merge(x, y)
    Candidate.new(x.prefix, x.match + y.prefix + y.match, y.suffix)
  end
end

class AtStart < Matcher
  def initialize(action)
    @action = action
  end

  def check(candidates)
    @action.call(candidates)
      .select {|candidate| candidate.prefix.empty? }
    end
  end
end

# regex = (MatchString.new("b") | MatchString.new("cd")) + AtStart.new(MatchString.new("c"))
# regex = Then.new(Or.new(MatchString.new("b"), MatchString.new("cd")), AtStart.new(MatchString.new("c")))
# regex = Then.new(MatchString.new("cd"), MatchString.new("e"))
regex = (MatchString.new("b") | MatchString.new("c")) +
        (AtStart.new(MatchString.new("cd")) | AtStart.new(MatchString.new("c")) | MatchString.new("f"))

# regex = MatchString.new("b") + AtStart.new(MatchString.new("c"))
# regex = (MatchString.new("b") | MatchString.new("c")) + MatchString.new("f")
def evaluate(action, string)
  result = action.call([Candidate.new("", string, "")].lazy)
  result = result.take(1).to_a
  if result
    puts "RESULT"
    puts result.inspect
  end
end
pp evaluate(regex, "abcdef")
