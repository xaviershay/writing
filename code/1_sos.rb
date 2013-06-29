# # The Mathematical Syntax of Small-step Operational Semantics
#
# _This writing was inspired by Chapter 2 of the excellent book [Understanding
# Computation](http://computationbook.com/). It is available free online, and
# is a fine piece of writing. My intent here is to introduce the mathematics
# that the book leaves as an exercise to the reader, and to further explore the
# fascinating world of small-step semantics._
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
# A program can be considered as the pairing of an _expression_ and an
# _environment_. The idea of small-step semantics is to repeatedly "reduce" a
# program by applying tiny transformations (_rules_) that modify either the
# expression, the environment, or both, until a program is reached that cannot
# be reduced any further. This is a useful way of describing a programming
# language in an umambiguous manner.
#
# Let's explore this concept with Ruby. To make things more readable in the
# code that follows, `[]` is aliased to `new` for all classes.
class Class
  def [](*args); new(*args) end
end

# Now consider a program that consists of a single constant number and an empty
# environment.  This is atomic, and cannot be reduced.

Number = Struct.new(:value) do
  def to_s;       value.to_s end
  def inspect;    "«#{self}»" end
  def reducible?; false end
end

exp, env = Number[10], {} # => [«10», {}]

# Not particularly interesting, and so far no math! Let's create an expression
# type that can be reduced: addition.
Add = Struct.new(:left, :right) do
  def to_s;       "%s + %s" % [left, right] end
  def inspect;    "«#{self}»" end
  def reducible?; true end
  def reduce(env)
    [Number.new(left.value + right.value), env, :addition]
  end
end

exp, env    = Add[Number[1], Number[2]], {} # => [«1 + 2», {}]
exp, env, _ = exp.reduce(env)               # => [«3», {}, :addition]

# An addition reduces to a number, also returning the particular transformation
# step that was used. We can define this more explicitly as a "rule". A rule
# contains a check for whether it should be applied to the given expression,
# and the actual logic to actually transform it if so.

class Add
  def self.rules
    [ AddValues[self] ]
  end

  def reduce(env)
    rule = self.class.rules.detect {|r| r.apply?(self) }
    rule.apply(self, env) << rule
  end
end

AddValues = Struct.new(:expression_type) do
  def apply?(*args); true end
  def apply(add, env)
    [Number[add.left.value + add.right.value], env]
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
# for. The add values rule can be expressed as a transition from one expression
# and environment to another.

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

print_all_rules
#     <x + y, σ> → <z, σ> if z is the sum of x and y

# In a sentence: "`x + y` reduces to the sum of `x` and `y` and does not change
# the environment." (σ = environment because math.)

# Now we can continually reduce an expression in tiny steps, printing out the
# exact mathematical rule that was applied at each step.

def print_line(exp, env, rule)
  puts "%15s | %s" % [exp.inspect + ', ' + env.inspect, rule]
end

def evaluate(exp, env = {})
  print_line exp, env, nil
  while exp.reducible?
    exp, env, rule = exp.reduce(env)
    print_line exp, env, format_rule(rule)
  end
rescue => e
  puts e.message
ensure
  puts
end

evaluate Add[ Number[1], Number[2] ]
#     «1 + 2», {} |
#         «3», {} | <x + y, σ> → <z, σ> if z is the sum of x and y


# Our operational semantics now contains only one rule: that of
# addition. What happens in the following case?

evaluate Add[ Number[1], Add[ Number[2], Number[3] ] ]
#     «1 + 2 + 3», {} |
#     undefined method `value' for «2 + 3»:Add

# An error! We have not defined a rule that can handle this case yet. It may
# seem obvious what the correct behaviour is, but small-step semantics is all
# about unambiguously defining even the tiniest step in our program, so we need
# to explictly answer the quest: What should happen if one side of the addition
# is an expression rather than a number?

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
    r =  exp.each.map.with_index {|x, i|
      i == n ? x.reduce(env)[0] : x
    }
    [exp.class.new(*r), env]
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

evaluate Add[ Number[1], Add[ Number[2], Number[3] ] ]
#     «1 + 2 + 3», {} |
#         «1 + 5», {} | <y, σ> → <y', σ> : <x + y, σ> → <x + y', σ>
#             «6», {} | <x + y, σ> → <z, σ> if z is the sum of x and y

# There is now a middle step that evaluates the nested addition. In a sentence,
# the mathematical notation translates to: "if expression `y` can reduce to
# `y'` without changing the environment, then `x + y` reduces to `x + y'` and
# does not change the environment." The "does not change the environment"
# clause (remember σ = environment) is redundant at the moment, but it will
# become useful later.
#
# In this case we have chosen to first try and evaluate the left side of the
# addition, then the right. We will see examples later on that would result in
# a different end state if the right side was evaluated first - this is why
# spelling out even tiny assumptions is important!
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
