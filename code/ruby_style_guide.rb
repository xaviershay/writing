# # Ruby Style Guide
#
# The personal style guide of [Xavier Shay](http://xaviershay.com). Any
# potential exceptions must be justified and documented. Code examples can be
# revealed by clicking ↩ , and these imply more rules than are explicitly
# labeled. Rules that I often use editor features or scripts to apply are
# notated with ⚙ and a link to details.
#
# Older code bases should migrate to this style, rather than stay consistent
# with themselves. Style upgrades should be in separate commits from behaviour
# changes.
#
# The canonical URL for this document is
# <a id='canonical-link' href="http://xaviershay.com/ruby-style-guide">http://xaviershay.com/ruby-style-guide</a>.
#
# ## Arrays
#
# * Use a trailing comma on final entry of multi-line definitions.

right = [
  1,
  2,
]

wrong = [
  1,
  2
]

# * Prefer `%w[]` for construction of string arrays.

right = %w[apples oranges]
wrong = %w(apples oranges)
wrong = ['apples', 'oranges']

# * Prefer `%i[]` for construction of symbol arrays. (Ruby >= 2.0 only)

right = %i[apples oranges grapes mangoes]
wrong = [:apples, :oranges, :grapes, :mangoes]


# ## Assignment
#
# * Prefer using instance variables rather than writer methods in
#   constructors.

class Right
  attr_writer :x, :y

  def initialize
    @x = []
    @y = []
  end
end

class Wrong
  attr_writer :x, :y

  def initialize
    self.x = []
    self.y = []
  end
end

# * Prefer separating assignment from conditionals.

right = true
42 if right

42 if wrong = true

# * If using an assignment as a boolean value in a conditional,
#   enclose in parentheses to indicate it's not a = vs == typo.

if (right = big_calculation)
if wrong = big_calculation
if right == big_calculation

# * Only use parallel assignment for short variable names or when splitting the
#   return value of a method.

x, y = "right", 42
long_name_one, long_name_two = right_method

long_name_one, long_name_two = "wrong", 0

# ## Blocks and Procs
#
# * Use curly-braces when block is being chained.

right = [].map {|x|
  x == 2
}.size

wrong = [].map do |x|
  x == 2
end.size

# * Use stabby syntax with parenthesis.

right = ->(x) { x }
wrong = -> x { x }
wrong = lambda {|x| x }

# * Omit parenthesis for zero-argument lambdas.

right = ->{ }
wrong = ->() { }

# * Prefer `Symbol#to_proc` where applicable.

right = [].map(&:length)
wrong = [].map {|x| x.length }

# * Use `.()` to call.

right = ->{ }.()
wrong = ->{ }.call
wrong = ->{ }[]

# ## Classes
#
# * Assign empty subclasses rather than inheriting.

Right = Class.new(StandardError)
class Wrong < StandardError; end

# * Assign struct subclasses so that they can be re-opened.

Right = Struct.new(:value) do
  def squared; value * value end
end

class Wrong < Struct.new(:value)
  def squared; value * value end
end

# * Alias `[]` to `new` for value objects.

right = Number[3]
wrong = Number.new(3)

# * Nest namespaced definitions.

class Namespace
  class Right; end
end

class Namespace::Wrong; end

# ## Conditionals
#
# * Only use ternary operator for very short conditionals. When in doubt,
#   avoid.

right = flag ? 42 : 36
right = if flag && other_flag
  long_name_one
else
  long_name_two
end

wrong = flag && other_flag ? long_name_one : long_name_two

# * Use `&&` and `||` in preference to `and` and `or`.

right if a && b
wrong if a and b

# ## Working around nil values
#
# * Prefer || to ternary for default value

right(possibly_nil_value || default_value)
wrong(possibly_nil_value ? possibly_nil_value : default_value)

# * Prefer ||= for memoization

right ||= big_calculation
wrong = big_calculation unless wrong

# * Prefer && for nil guards

right = object && object.name
wrong = object ? object.name : nil
wrong = object.name if object

# ## Dependencies
#
# * Explicitly require third-party code in each file it is used.
# * Prefer constant stubbing when depending on code that you own.

def my_method; MyCollaborater.does_something end

it do
  collaborator = class_double("MyCollaborator").as_stubbed_const
  collaborator.should_receive(:does_something)

  my_method
end

# * Prefer constructor or parameter injection when depending on code you do not
#   own. When providing code to others, include fake versions of your classes.

def my_method(client = Service::Client); client.echo('hello') end

it do
  client = Service::FakeClient.new
  my_method(client)

  expect(client.echoes).to eq(['hello'])
end

# ## Hashes
#
# * Use a trailing comma on final entry of multi-line definitions.

right = {
  a: 1,
  b: 2,
}

wrong = {
  a: 1,
  b: 2
}

# * Prefer 1.9 syntax, though stay consistent within a single definition.

right = {
  :a   => 1,
  'ab' => 2,
}

wrong = {
  a: 1,
  'abc' => 2,
}

# * Construct from an array using `each_with_object`.

right = (1..10).each_with_object({}) {|x, h| h[x] = x ** 2 }
wrong = Hash[(1..10).map {|x| [x, x ** 2] }]
wrong = (1..10).reduce({}) {|h, x| h.update(x => x ** 2) }

# * Omit `{}` when passing as the last argument to a method.

right(a: 1)
wrong({a: 1})

# * Prefer `fetch` for providing default values.

right = {}.fetch(:a, 0)
wrong = {}[:a] || 0

# ## Enumeration
#
# * Prefer lisp-style enumeration methods.

right.map     { ... }
wrong.collect { ... }

right.reduce(seed) { ... }
wrong.inject(seed) { ... }

right.find   { ... }
right.detect { ... }

# Select is an exception for symmetry with `reject`.
right.select   { ... }
wrong.find_all { ... }

right.reject { ... }
wrong.there_is_no_wrong_way_to_reject { ... }

# ## Line Length
#
# * 80 characters is good enough for anyone.
#   [⚙](http://vimdoc.sourceforge.net/htmldoc/change.html#gq)
# * Long URLs are exempt, though consider shortening them.
# * Line up method arguments when they do not fit on one line.

def right_method(long_param_one,
                 long_param_two,
                 long_param_three,
                 long_param_four)
  42
end

def wrong_method(long_param_one, long_param_two, long_param_three, long_param_four)
  42
end

# * Squeeze multiline strings if you need to remove newlines.

<<-EOS.strip.gsub(/\s+/, ' ')
  But we refuse to believe that the bank of justice is bankrupt. We refuse to
  believe that there are insufficient funds in the great vaults of opportunity
  of this nation. And so we have come to cash this check, a check that will
  give us upon demand the riches of freedom and the security of justice.
EOS

# * Use `sprintf` to interpolate variables into long strings.

right = "%s thinks that %s should %s" % [
  long_variable_one,
  long_variable_two,
  long_variable_three
]

wrong = "#{long_variable_one} thinks that #{long_variable_two} should #{long_variable_three}"

# * One line per method for long chains.

right = (1..10)
  .map {|x| x + 1 }
  .select(&:odd?)

wrong = (1..10).map {|x| x + 1 }.select(&:odd?)

# ## Methods
#
# * Use parentheses to enclose parameters in method definitions

def right(*args)
end

def wrong *args
end

# * Use a single line for blocks of trivial methods.

def top;    @top    ||= @rect.top    end
def right;  @right  ||= @rect.right  end
def bottom; @bottom ||= @rect.bottom end
def left;   @left   ||= @rect.left   end

def wrong
  @wrong ||= []
end

# * Use `_` for ignored arguments.

def right(x, _); x end
def wrong(x, y); x end

# * Use `*` when all arguments are ignored.

def right(*); 42 end
def wrong(_, _); 42 end

# * Prefer using parentheses to send messages with arguments.

object.right(17, 23)
object.wrong 17, 23

# * Uses parentheses to send messages with arguments when consuming return value.

puts right(42)
puts wrong 42

# * Omit parentheses when message has no arguments

object.right
object.wrong()

# * Omit parentheses for DSLs or readability when the method has no interesting return value

do_the right thing
do_the(wrong thing)

puts :right
puts(:ymmv)

# ## Naming
#
# * Use short variable names for short blocks where it is obvious what the
#   variable is.

right = bird_names.map {|x| x.to_s.length }
wrong = bird_names.map {|bird_name| bird_name.to_s.length }

# * Use short variable names for math.

right = v * t + 0.5 * a * t ** 2
wrong = velocity * time + 0.5 * acceleration * time ** 2

# * Use `?` suffix for methods rather than `has_` or `is_` prefix.

def valid?; "right" end
def is_valid?; "wrong" end
def has_valid?; "wrong" end

# * Use modules or classes for namespacing rather than suffixes, except when
#   necessarily following [Rails](http://rubyonrails.org/) conventions.

Example::Right
WrongExample

# * Avoid double namespacing.

right = bird.name
wrong = bird.bird_name

# ## Regexes
#
# * Make with `%r{}` when escaping of slashes would otherwise be required.

right = %r{/some/path}
wrong = /\/some\/path/

# * Use `\A` and `\z` rather than `^` and `$` for start and end of line
#   matching.

right = "hello\nthere" =~ /\Ahello\z/
wrong = "hello\nthere" =~ /^hello$/

# * Use `String#[]` for extraction.

right = "http://example.com"[%r{\A(http(s)?)://}, 1]
wrong = %r{(http(s)?)://}.match("http://")[1]

# ## Whitespace
#
# * No trailing whitespace.
#   [⚙](https://github.com/xaviershay/dotfiles/blob/master/vimrc#L95)
# * Two space indentation.

def my_method
  if rand < 0.5
    if rand > 0.5
      42
    end
  end
end

# * No indent after `private` or `protected` modifiers.

class Right
  private

  def my_method; 42 end
end

class Wrong
  private

    def my_method; 42 end
end


# * Align `if` blocks with left indent.

right = if rand < 0.5
  0
else
  1
end

wrong = if rand < 0.5
          0
        else
          1
        end

# * Align 1.8 style hashes along hash rocket.
#   [⚙](https://github.com/xaviershay/dotfiles/blob/master/bin/format_hash.rb)

right = {
  'a'   => 1,
  'ab'  => 2,
  'abc' => 3,
}

wrong = {
  'a' => 1,
  'ab' => 2,
  'abc' => 3,
}

# * Align 1.9 style hashes along right-hand side.
#   [⚙](https://github.com/xaviershay/dotfiles/blob/master/bin/format_hash.rb)

right = {
  a:   1,
  ab:  2,
  abc: 3,
}

wrong = {
  a: 1,
  ab: 2,
  abc: 3,
}

# * Align assignment along equals sign.
#   [⚙](https://github.com/xaviershay/dotfiles/blob/master/bin/format_hash.rb)

a  = "right"
ab = "right"

a = "wrong"
ab = "wrong"

# * No space between block brace and parameters.

right = [].map {|x| x }
wrong = [].map { |x| x }

# * No space between method definition name, argument, and bracket.

def right(x); end
def wrong (x); end
def wrong( x ); end

# * No space between method call name, argument, and bracket.
right(42)
wrong (42)
wrong( 42 )

#
# <div class='footer-link'><a href='https://github.com/xaviershay/writing/blob/master/code/ruby_style_guide.rb'>Source
# for this document</a></div>
# <script src='http://code.jquery.com/jquery-1.10.2.min.js'></script>
# <script src='../assets/style_guide.js'></script>
# <link href='../assets/style_guide.css' rel='stylesheet'>
