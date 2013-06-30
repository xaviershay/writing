# # The Mathematical Syntax of Small-step Operational Semantics
#
# ## Working With An Environment
#
# Until now, none of our semantic definitions have interacted with the
# environment. In this section we will add some new expression types that do
# so, but before jumping in let's quickly recap the behaviour we have so far
# added to expressions.

require_relative '1_sos'

module Expression
  def inspect; "«#{self}»" end
  def reducible?; true end
  def reduce(env)
    rule = self.class.rules.detect {|r| r.apply?(self) }
    rule.apply(self, env)
  end

  def self.included(klass)
    klass.instance_eval do
      def rules;     [] end
      def labels;    [] end
      def prototype; new(*labels) end
    end
  end
end

# We have ways to:
#
# * Display a specific instance of expression.
# * Evaluate that instance.
# * Display a meta-instance of the expression for use in the mathematical
#   notation (the "prototype").
#
# All expressions going forward will share this behaviour.

# The simplest expression that can be built to interact with the environment is
# one to read a value out of it.
ReadVariable = Struct.new(:name) do
  include Expression

  def to_s; name.to_s end
  def self.rules;  [ ReadFromEnv[self] ] end
  def self.labels; [:x] end
end

ReadFromEnv = Struct.new(:expression_type) do
  def apply?(*_); true end
  def apply(exp, env)
    Reduction[
      Program[ exp, env ],
      Program[ env.fetch(exp.name), env ],
      self, []
    ]
  end

  def antecedent; '' end
  def to_s
    '<%s, σ> → <σ(%s), σ>' % [
      expression_type.prototype,
      expression_type.prototype
    ]
  end
  def clause
    'if %s ∈ dom(σ)' % expression_type.labels
  end
end

evaluate ReadVariable[:a], {a: Number[4]}
#     «a», a:«4» | <x, σ> → <σ(x), σ> if x ∈ dom(σ)
#     «4», a:«4» |

# There is some new notation here. Recall that `σ` refers to the environment.
# `σ(x)` means _fetch the value for `x` from the environment_, `dom(σ)` refers
# to the names of everything in the environment (the _domain_), and `x ∈ ` means
# _`x` is an element of_.
#
# It is tempting to take the _`x` is in the domain_ clause for granted, but
# spelling it out here to makes it clear that it does not apply to any
# arbitrary expression. The clause adds clarity as to what the variables in the
# notation are.
#
# Combining them together, a sentence for the full notation reads _the
# expression `x` reduces to the value of `x` in the environment, given `x`
# is the name of something in the environment_.
#
# Our current semantics does not restrict the types of things that can be
# stored in an environment. This allows some interesting exucutions, such as if
# you store an expression rather than a number. This type of behaviour is not
# usually well-defined without a good semantics!

evaluate Add[ ReadVariable[:a], Number[2] ], {a: Add[ Number[4], Number[3] ]}
#     «a + 2», a:«4 + 3»       | <x, σ> → <x', σ> : <x + y, σ> → <x' + y, σ>
#       «a», a:«4 + 3»         | <x, σ> → <σ(x), σ> if x ∈ dom(σ)
#       «4 + 3», a:«4 + 3»     |
#     «(4 + 3) + 2», a:«4 + 3» | <x, σ> → <x', σ> : <x + y, σ> → <x' + y, σ>
#       «4 + 3», a:«4 + 3»     | <x + y, σ> → <z, σ> if z is the sum of x and y
#       «7», a:«4 + 3»         |
#     «7 + 2», a:«4 + 3»       | <x + y, σ> → <z, σ> if z is the sum of x and y
#     «9», a:«4 + 3»           |

# ### Writing
#
# Introducing an expression to change the environment poses an interesting
# question: what should that expression itself reduce to? Three readily come to
# mind:
#
# * Itself, ensuring that if the value is already in the environment it applies
#   an identity transform.
# * A new type of terminal expression (such as `null`).
# * The value that it puts into the environment.
#
# The first would need a change to the concept of `reducible?`. Currently it is
# constant with respect to the type of expression, but could be changed to
# either take into account the environment or to collapse the concept entirely
# into `reduce` and be determined implicitly (i.e. if an expression does not
# reduce to itself then it is reducible). This is an interesting exercise, but
# somewhat of a tangent. We will revisit it later.
#
# Instead, we will start with the second approach and introduce a null value
# before investigating the third.
class Null
  include Value
  def to_s; '∅' end
end

WriteVariable = Struct.new(:name, :value) do
  include Expression

  def to_s; "%s = %s" % [name, value] end
  def self.rules;  [ WriteToEnv[self] ] end
  def self.labels; [:x, :v] end
end

WriteToEnv = Struct.new(:expression_type) do
  def apply?(*_); true end
  def apply(exp, env)
    Reduction[
      Program[ exp, env ],
      Program[ Null[], env.merge(exp.name => exp.value) ],
      self, []
    ]
  end

  def antecedent; '' end
  def to_s
    '<%s, σ> → <%s, σ[%s ↦ %s]>' % [
      expression_type.prototype,
      Null[],
      *expression_type.labels
    ]
  end
  def clause; '' end
end

evaluate WriteVariable[:a, Number[3]]
#     «a = 3»    | <x = v, σ> → <∅, σ[x ↦ v]>
#     «∅», a:«3» |

# The only new notation here is `↦`, which simply puts a new entry into the
# environment.  As expected, returning null prevents variable assignment from
# being nested inside other expressions.

evaluate Add[ WriteVariable[:a, Number[3]], Number[2] ]
#     «(a = 3) + 2» | <x, σ> → <x', σ> : <x + y, σ> → <x' + y, σ>
#       «a = 3»     | <x = v, σ> → <∅, σ[x ↦ v]>
#       «∅», a:«3»  |
#     «∅ + 2»       | undefined method `value' for «∅»:Null

# Under these semantics a value can be set in the environment, but there is no
# way to ever use it! A _sequence_ expression that enables expressions to be reduced one after the other will allow these variables to be used.
Sequence = Struct.new(:left, :right) do
  include Expression

  def to_s; "%s; %s" % [left, right] end
  def self.rules
    [
      ReduceArgumentWithEnv[self, 0],
      ReduceArgumentWithEnv[self, 1],
      SelectArgument[self, 1]
    ]
  end
  def self.labels; [:x, :y] end
end

# A sequence expression first reduces each of its sub-expressions, before
# throwing away the first one and returning the second. The previous argument
# reduction we used for addition is insufficient, since it does not allow the
# environment to be changed.

ReduceArgumentWithEnv = Struct.new(:expression_type, :n) do
  def apply?(exp); exp[n].reducible?  end
  def apply(exp, env)
    sub_reduction = nil
    new_env       = env

    sub_exps = exp.each.map.with_index {|sub_exp, i|
      if i == n
        sub_reduction = sub_exp.reduce(env)
        new_env       = sub_reduction.to.env
        sub_reduction.to.exp
      else
        sub_exp
      end
    }

    Reduction[
      Program[ exp, env ],
      Program[ expression_type.new(*sub_exps), new_env ],
      self, [sub_reduction]
    ]
  end

  def antecedent
    label = expression_type.labels[n]
    "<%s, σ> → <%s, σ'>" % [label, "#{label}'"]
  end
  def to_s
    "<%s, σ> → <%s, σ'>" % [
      expression_type.prototype,
      expression_type.new(*expression_type.labels.map.with_index {|label, i|
        i == n ? "#{label}'" : label
      })
    ]
  end
  def clause; '' end
end

SelectArgument = Struct.new(:expression_type, :n) do
  def apply?(*_); true end
  def apply(exp, env)
    Reduction[
      Program[ exp, env ],
      Program[ exp[n], env ],
      self, []
    ]
  end

  def antecedent; '' end
  def to_s
    "<%s, σ> → <%s, σ>" % [
      expression_type.prototype,
      expression_type.labels[n]
    ]
  end
  def clause; '' end
end

evaluate Sequence[ WriteVariable[:a, Number[3]], ReadVariable[:a] ]
#     «a = 3; a»    | <x, σ> → <x', σ'> : <x; y, σ> → <x'; y, σ'>
#       «a = 3»     | <x = v, σ> → <∅, σ[x ↦ v]>
#       «∅», a:«3»  |
#     «∅; a», a:«3» | <y, σ> → <y', σ'> : <x; y, σ> → <x; y', σ'>
#       «a», a:«3»  | <x, σ> → <σ(x), σ> if x ∈ dom(σ)
#       «3», a:«3»  |
#     «∅; 3», a:«3» | <x; y, σ> → <y, σ>
#     «3», a:«3»    |

# The notation introduced here does not contain any new concepts, and is
# hopefully starting to become familiar.
#
# What happens if instead of reducing to null, writing to the environment
# reduces the value being written instead? Writes could then be nested inside
# other expressions.
class WriteToEnv
  def apply(exp, env)
    Reduction[
      Program[ exp, env ],
      Program[ exp.value, env.merge(exp.name => exp.value) ],
      self, []
    ]
  end

  def to_s
    '<%s, σ> → <%s, σ[%s ↦ %s]>' % [
      expression_type.prototype,
      expression_type.labels[1],
      *expression_type.labels
    ]
  end
end

evaluate Add[ WriteVariable[:a, Number[3]], ReadVariable[:a] ]
#     «(a = 3) + a» | <x, σ> → <x', σ> : <x + y, σ> → <x' + y, σ>
#       «a = 3»     | <x = v, σ> → <v, σ[x ↦ v]>
#       «3», a:«3»  |
#     «3 + a»       | key not found: :a

# It doesn't work! As alluded to early, add is using the returned value, but
# throwing away the new environment. That is why we needed to implement a new
# reduce with environment rule. Small-step operational semantics does not let
# anything slip through the cracks! Updating add to use the new reduce with
# argument step that sequence uses fixes the issue.

class Add
  def self.rules
    [
      ReduceArgumentWithEnv[self, 0],
      ReduceArgumentWithEnv[self, 1],
      AddValues[self]
    ]
  end
end

evaluate Add[ WriteVariable[:a, Number[3]], ReadVariable[:a] ]
#     «(a = 3) + a»  | <x, σ> → <x', σ'> : <x + y, σ> → <x' + y, σ'>
#       «a = 3»      | <x = v, σ> → <v, σ[x ↦ v]>
#       «3», a:«3»   |
#     «3 + a», a:«3» | <y, σ> → <y', σ'> : <x + y, σ> → <x + y', σ'>
#       «a», a:«3»   | <x, σ> → <σ(x), σ> if x ∈ dom(σ)
#       «3», a:«3»   |
#     «3 + 3», a:«3» | <x + y, σ> → <z, σ> if z is the sum of x and y
#     «6», a:«3»     |

# This also demonstrates the impact of our earlier decision to evaluate
# addition reduction left to right. Under right to left semantics, the above
# program would not execute since `a` would not be defined.
