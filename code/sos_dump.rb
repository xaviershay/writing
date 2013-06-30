
# By these semantics, referencing a variable that does not exist causes an
# error. We could instead and a step to provide a default value (such as
# instance variables in Ruby).
# TODO: How to restrict this (in math) from matching all expressions?

class ReadVariable
  def self.rules
    [
      ReadFromEnv[self],
      ReduceConstant[self, Number[0]]
    ]
  end
end

class ReadFromEnv
  def apply?(exp, env); env.has_key?(exp.name) end

  def antecedent
    '%s ∈ dom(σ)' % expression_type.labels
  end
  def to_s
    '<%s, σ> → <σ(%s), σ>' % [
      expression_type.prototype,
      expression_type.prototype
    ]
  end
  def clause; '' end
end

ReduceConstant = Struct.new(:expression_type, :constant_exp) do
  def apply?(*_); true end
  def apply(exp, env)
    Reduction.new(
      [exp, env],
      [constant_exp, env],
      self,
      []
    )
  end

  def antecedent; '' end
  def to_s
    '<%s, σ> → <%s, σ>' % [
      expression_type.prototype,
      constant_exp
    ]
  end
  def clause; '' end
end

evaluate Add[ReadVariable[:a], ReadVariable[:b]], {a: Number[4]}
