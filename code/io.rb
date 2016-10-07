require 'pp'

class Matcher
  def call(match, debug: false)
    return unless match

    check(match)
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

  def check(match)
    string = match[1]

    tokens = string.split(@substr, 2)
    if tokens.size == 2
      [
        tokens[0],
        @substr,
        tokens[1]
      ]
    end
  end
end

class Or < Matcher
  def initialize(lhs, rhs)
    @lhs = lhs
    @rhs = rhs
  end

  def check(match)
    @lhs.call(match) || @rhs.call(match)
  end
end

class Then < Matcher
  def initialize(lhs, rhs)
    @lhs = lhs
    @rhs = rhs
  end

  def check(match)
    left = @lhs.call(match)

    if left
      right = @rhs.call([left[0] + left[1], left[2], ""])
      if right
        [
          left[0],
          left[1] + right[0] + right[1],
          right[2]
        ]
      end
    end
  end
end

class AtStart < Matcher
  def initialize(action)
    @action = action
  end

  def check(match)
    candidate = @action.call(match)

    return unless candidate

    if candidate[0] == ""
      candidate
    end
  end
end

regex = (MatchString.new("b") | MatchString.new("cd")) + AtStart.new(MatchString.new("c"))
# regex = Then.new(Or.new(MatchString.new("b"), MatchString.new("cd")), AtStart.new(MatchString.new("c")))
# regex = Then.new(MatchString.new("cd"), MatchString.new("e"))
# regex = MatchString.new("a")

def evaluate(action, string)
  result = action.call(["", string, ""])
  if result
    true
  else
    false
  end
end
pp evaluate(regex, "abcdef")

exit

class RejectOdd
  def call(xs)
    xs.reject {|x| x.odd? }
  end
end

class IOAction
  def >>(action)
    CompositeIOAction.new(self, action)
  end

  def >=(f)
    SequencedIOAction.new(self, f)
  end
end

class CompositeIOAction < IOAction
  def initialize(lhs, rhs)
    @lhs = lhs
    @rhs = rhs
  end

  def call
    @lhs.call
    @rhs.call
  end
end

class SequencedIOAction < IOAction
  def initialize(lhs, f)
    @lhs = lhs
    @f = f
  end

  def call
    rhs = @f.call(@lhs.call)
    rhs.call
  end
end

class PutStrLn < IOAction
  def initialize(str)
    @str = str
  end

  def call
    puts @str
  end
end

class GetLine < IOAction
  def call
    gets
  end
end

action = PutStrLn.new("Hello") >> PutStrLn.new("World")
action = PutStrLn.new("What is your name?") >> GetLine.new >= lambda {|x| PutStrLn.new("Hello " + x) }

require 'pp'
pp action
# action.call

# IOAction.new(:puts)
# [[:putStrLn, "What is your name?"], lambda {|_|
#  [[:getLine], lambda {|x| [[:putStrLn, "hello " + x]] }]]
