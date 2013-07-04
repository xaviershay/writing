# # The Mathematical Syntax of Small-step Operational Semantics
#
# _This writing was inspired by Chapter 2 of the excellent book [Understanding
# Computation](http://computationbook.com/). It is available free online, and
# is a fine piece of writing. My intent here is to introduce the mathematics
# that the book leaves as an exercise to the reader, and to further explore the
# fascinating world of small-step semantics._
#
# ## Introduction
#
# Small-step semantics is one way (among many) to rigorously define how a
# program should execute, including how and when expressions are evaluated, how
# the environment is manipulated, and so on.
#
# This chapter introduces a fairly standard mathematical notation devised by
# Gordon Plotkin in 1981 for expressing small-step semantics. It looks scary if
# you are not a mathematician, but don't worry! We'll work through it in small
# steps of our own.
#
# A running program can be considered as the pairing of an _expression_ and an
# _environment_. The idea of small-step semantics is to repeatedly _reduce_ a
# program by applying tiny transformations (_rules_) that modify either the
# expression, the environment, or both, until a program is reached that cannot
# be reduced any further. A program execution is then a series of reductions.
# This is a useful way of describing a programming language in an umambiguous
# manner.
Program = Struct.new(:exp, :env) do
  def inspect
    x = exp.inspect
    unless env.empty?
      env.each do |name, value|
        x += ", #{name}:#{value.inspect}"
      end
    end
    x
  end

  def reduce
    exp.reduce(env)
  end
end

Reduction = Struct.new(
  :from,    # Initial program state.
  :to,      # Program state after reduction.
  :by,      # What rule was used to transform state.
  :children # Allow reductions to be nested for ease of visualization.
)

# Let's explore this concept with Ruby. To make things more readable in the
# code that follows, `[]` is aliased to `new` for all classes.
class Class
  def [](*args); new(*args) end
end

# Now consider a program that consists of a single constant number and an empty
# environment. Its reduction is an identify function.

Identity = Class.new

module Value
  def inspect;    "«#{self}»" end
  def reducible?; false end
  def reduce(env)
    identity = Program[self, env]
    Reduction[identity, identity, Identity[], []]
  end
end

Number = Struct.new(:value) do
  include Value
  def to_s; value.to_s end
end

Program[ Number[10], {} ] # => «10»

# Not particularly interesting, and so far no math! Let's create an expression
# type that can be reduced: addition.
Add = Struct.new(:left, :right) do
  def to_s
    [left, right].map {|x|
      if x.respond_to?(:members) && x.members.size > 1
        "(%s)"
      else
        "%s"
      end % x
    }.join(' + ')
  end
  def inspect;    "«#{self}»" end
  def reducible?; true end
  def reduce(env)
    Reduction[
      Program[ self, env ],
      Program[ Number[left.value + right.value], env ],
      :addition,
      []
    ]
  end
end

p  = Program[ Add[Number[1], Number[2]] ] # => «1 + 2»
p2 = p.reduce
p2.to                                     # => «3»
p2.by                                     # => :addition

# An addition reduces to a number, also returning the particular transformation
# step that was used. We can define this more explicitly as a _rule_. A rule
# contains a check for whether it should be applied to the given expression,
# and the actual logic to actually transform it if so.

class Add
  def self.rules
    [ AddValues[self] ]
  end

  def reduce(env)
    rule = self.class.rules.detect {|r| r.apply?(self) }
    rule.apply(self, env)
  end
end

AddValues = Struct.new(:expression_type) do
  def apply?(*_); true end
  def apply(add, env)
    Reduction[
      Program[ add, env ],
      Program[ Number[add.left.value + add.right.value], env ],
      self,
      []
    ]
  end
end

# More code for the same output, but now a list of rules for the system - our
# operational semantics - can be printed.

def format_rule(rule)
  rule.class
end

def print_all_rules
  Add.rules.each do |rule|
    puts format_rule(rule)
  end
  puts
end
print_all_rules
#     AddValues

# These rules are what Plotkin (back in 1981) devised a consistent notation
# for. The notation consists of the rule itself, an antecendent (precondition),
# and a clause (explantory detail for the variables). With some small
# extensions, each of these can be added to our existing rules.

class Add
  def self.labels;    [:x, :y] end
  def self.prototype; new(*labels) end
end

class AddValues
  def antecedent; '' end
  def to_s;   '<%s, σ> → <z, σ>'             % expression_type.prototype end
  def clause; 'if z is the sum of %s and %s' % expression_type.labels end
end

def format_rule(rule)
  if rule.antecedent.empty?
    "%s %s" % [rule, rule.clause]
  else
    "%s : %s %s" % [rule.antecedent, rule, rule.clause]
  end
end

class Identity
  def antecedent; '' end
  def to_s;       '' end
  def clause;     '' end
end

print_all_rules
#     <x + y, σ> → <z, σ> if z is the sum of x and y

# `<e, σ>` represents a program, the expression being `e` and the environment
# `σ`. In a sentence, the above notation can be read: _The program `x + y`
# reduces to the sum of `x` and `y` and does not change the environment._

# Now we can continually reduce an expression in tiny steps, printing out the
# exact mathematical rule that was applied for each, until we reach a terminal
# point where our reduction is the indentity function and nothing more of
# interest will occur.

def evaluate(exp, env = {})
  program = Program[ exp, env ]
  last    = nil
  lines   = []

  while true
    reduction = program.reduce

    lines += format_reduction(reduction)

    break if reduction.by.is_a?(Identity)

    program = reduction.to
  end
rescue => e
  lines << [program.inspect, e.message]
ensure
  widest_column_size = lines.map {|x| x[0].length }.max
  lines.each do |line|
    puts "%-#{widest_column_size}s | %s" % line
  end
  puts
end

def format_line(indent, program, rule)
  [ (' ' * indent) + program.inspect, rule ]
end

def format_reduction(reduction, indent = 0)
  lines = []
  lines << format_line(indent, reduction.from, format_rule(reduction.by))

  reduction.children.each do |child|
    lines += format_reduction(child, indent + 2)
  end

  if r = reduction.children.last
    lines << format_line(indent + 2, r.to, format_rule(Identity[]))
  end
  lines
end

# The result of all this hard work is that we can now inspect each step of a
# program reduction.

evaluate Add[ Number[1], Number[2] ]
#     «1 + 2» | <x + y, σ> → <z, σ> if z is the sum of x and y
#     «3»     |

# Our operational semantics now contains only one rule: that of
# addition. What happens in the following case?

evaluate Add[ Number[1], Add[ Number[2], Number[3] ] ]
#     «1 + (2 + 3)» | undefined method `value' for «2 + 3»:Add

# An error! We have not defined a rule that can handle this case yet. It may
# seem obvious what the correct behaviour is, but small-step semantics is all
# about unambiguously defining even the tiniest step in our program, so we need
# to explictly answer the question: What should happen if one side of the
# addition is an expression rather than a number?

class Add
  def self.rules
    [
      ReduceArgument[self, 0],
      ReduceArgument[self, 1],
      AddValues[self]
    ]
  end
end

ReduceArgument = Struct.new(:expression_type, :n) do
  def apply?(exp); exp[n].reducible?  end
  def apply(exp, env)
    sub_reduction = nil
    args = exp.each.map.with_index {|sub_exp, i|
      if i == n
        sub_reduction = sub_exp.reduce(env)
        sub_reduction.to[0]
      else
        sub_exp
      end
    }

    Reduction[
      Program[ exp, env ],
      Program[ expression_type.new(*args), env ],
      self,
      [sub_reduction]
    ]
  end

  def antecedent
    label = expression_type.labels[n]
    "<%s, σ> → <%s, σ>" % [label, "#{label}'"]
  end
  def to_s
    '<%s, σ> → <%s, σ>' % [
      expression_type.prototype,
      expression_type.new(*expression_type.labels.map.with_index {|label, i|
        i == n ? "#{label}'" : label
      })
    ]
  end
  def clause; '' end
end

evaluate Add[ Number[1], Add[Number[2], Number[3]] ]
#     «1 + (2 + 3)» | <y, σ> → <y', σ> : <x + y, σ> → <x + y', σ>
#       «2 + 3»     | <x + y, σ> → <z, σ> if z is the sum of x and y
#       «5»         |
#     «1 + 5»       | <x + y, σ> → <z, σ> if z is the sum of x and y
#     «6»           |

# There is a new first step that reduces the nested addition, with some new
# notation. In a sentence, it translates to: _if expression `y` can reduce to
# `y'` without changing the environment, then `x + y` reduces to `x + y'` and
# does not change the environment._ Not changing the environment is redundant
# at the moment, since _nothing_ in our semantics can change it, but this
# concept will become useful later.
#
# We have chosen to first try and reduce the left side of the addition, then
# the right. We will see examples later on that would result in a different end
# state if the right side was reduced first - this is why spelling out even
# tiny assumptions is important!
#
# We have been using, and will continue to use, a condensed horizontal form of
# the mathematical notation since is much easier to include beside sample
# executions. In case you come across it in the wild, here is the complete
# operational semantics for our addition engine, using a more vertical
# formatter.

def print_rule_vertical(rule)
  puts rule.antecedent.to_s
  puts "―" * rule.to_s.length + ' ' + rule.clause
  puts rule.to_s
  puts
end

Add.rules.each {|rule| print_rule_vertical(rule) }

#     <x, σ> → <x', σ>
#     ――――――――――――――――――――――――
#     <x + y, σ> → <x' + y, σ>
#
#     <y, σ> → <y', σ>
#     ――――――――――――――――――――――――
#     <x + y, σ> → <x + y', σ>
#
#
#     ――――――――――――――――――― if z is the sum of x and y
#     <x + y, σ> → <z, σ>

# In the next section we will introduce environment modification to our
# semantics and see where that leads us.
