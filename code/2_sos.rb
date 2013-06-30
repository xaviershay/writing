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
    rule = self.class.rules.detect {|r| r.apply?(self, env) }
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

# The simplest expression we can build to interact with the environment is to
# read a value out of it.
ReadVariable = Struct.new(:name) do
  include Expression

  def to_s; name.to_s end

  def self.rules
    [ ReadFromEnv[self] ]
  end
  def self.labels; [:x] end
end

ReadFromEnv = Struct.new(:expression_type) do
  def apply?(*_); true end
  def apply(exp, env)
    Reduction.new(
      Program[ exp, env ],
      Program[ env.fetch(exp.name), env ],
      self,
      []
    )
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
# It is tempting to take the _`x` is in the domain_ clause for granted, but we
# spell it out here to make it clear it  does not apply to any arbitrary
# expression. The clause adds clarity as to what the variables in the notation
# are.
#
# Combining them together, a sentence for the full notation reads _the
# expression `x` reduces to the value of `x` in the environment, given `x`
# exists in the environment_.
#
# Our current semantics does not restrict the types of things that can be
# stored in an environment. This allows some interesting exucutions, such as if
# you store an expression rather than a number. This type of behaviour is not
# usually well-defined without a good semantics!

evaluate Add[ ReadVariable[:a], Number[2] ], {a: Add[ Number[4], Number[3] ]}
#     «a + 2», a:«4 + 3»     | <x, σ> → <x', σ> : <x + y, σ> → <x' + y, σ>
#       «a», a:«4 + 3»       | <x, σ> → <σ(x), σ> if x ∈ dom(σ)
#       «4 + 3», a:«4 + 3»   |
#     «4 + 3 + 2», a:«4 + 3» | <x, σ> → <x', σ> : <x + y, σ> → <x' + y, σ>
#       «4 + 3», a:«4 + 3»   | <x + y, σ> → <z, σ> if z is the sum of x and y
#       «7», a:«4 + 3»       |
#     «7 + 2», a:«4 + 3»     | <x + y, σ> → <z, σ> if z is the sum of x and y
#     «9», a:«4 + 3»         |
