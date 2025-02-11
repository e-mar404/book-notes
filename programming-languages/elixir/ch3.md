# Control Flow

Conditional constructs such as if and case, are often relaxed with multi clause
functions, and there are no loop statements, such as while.

## Pattern Matching

In an expression like so `person = {"Bob", 25}` the left side is called the
pattern and the right side is an expression that evaluates to an elixir term.
Just like any other expression on elixir pattern matching also returns a value.

Matching isn't confined to destructuring tuple elements to individual variables.
Even constants are allowed on the left side of the match expression.     

A variable can be referenced multiple times but this does not change the value
that the variable holds. The value will be the same.

Using `^` in variable name declaration means that you expect that object to be
in that same position when doing pattern matching.

### Lists

Matching lists is more often done by relying on their recursive nature. Each
non-empty list is a recursive structure that can be expressed in the form of
\[head | tail\]

Thinking about lists having a recursive structure makes me think how well are
Tail Call Optimizations implemented in elixir. From the looks of it you should
choose either regular recursion vs TOC depending on the situation and that one
is not better or worse than the other in all cases (as always it depends).

[Nobbz from elixir
forum](https://elixirforum.com/t/tail-call-optimization-in-elixir-erlang-not-as-efficient-and-important-as-you-probably-think/880)

    "When building a list which order matters, it does not really matter if you
    build it “on the stack” or in an accumulator which you reverse afterwards.
    One of both might kill the stack, the other one just will stress your GC.
    But whenever order of the resulting list does not matter anymore or when you
    reduce to a single value, an accumulater in a tail recursive function is way
    better, because it is faster and does not stress the stack that much" ###
    Bitstrings and Binaires

Matching bitstrings and binaries is immensely useful when you're trying to parse
packed binary content that comes from a file, and external device, or a network

Also take a look at multi clause functions and guards.

### Guards

Should try not to use guards in order to do type checking. Heard this from a
podcast where Sasha was talking in, this is usually bad practice and make the
code more noisy.

## Classical Branching

Multi clause functions are not always the solution since they create unnecessary
code, for times like this if, else unless and cond come in handy. This clauses
can either be inline of regular block clojures.

Remember since everything in elixir is an expression the if statement returns
the result of the executed block of code, this lets an if statement be the only
thing that is inside a function body since the function's implicit return will
return the result of the if statement.

Another cool feature is the use of unless which is just a shorthand more
idiomatic way of doing if x not eq to y -> unless x eq y

*Cond*

The cond expression can be thought of as an equivalent of an if else if
statement but it will branch off to the first case that results into true. You
can have a default branch if the expression being evaluated is just the boolean
true.

*Case*

This is similar to a switch statement which will match the expression at the top
to one of the patterns to be branched out of. This is most useful when there is
no need to create a multi clause function, there is not much difference between
either.


Multi clauses offer a more declarative feel to branching, but they require you
to define a separate function and pass all the necessary args to it. Classical
expressions seem more imperative but can often prove simpler than multi clause
approach.

### With expression

Very useful when you need to chain a couple of expressions and return the error
of the first expression that fails.

Example. Process registration data from a user.

The input being a map with keys that are strings ("login", "email", and
"password", etc). 

The task is to normalize this map into a map that contains only fields login,
email, and password. If the given map does have all three required fields that
it is as easy to return the map with atoms. If there is one missing field then
it is not as easy and you need to find a way to return one of two value, {:ok,
result} or {:error, reason}.

A naive way to code this would be with a bunch of branching at each step of
extraction of a part of the form. A better way is to use the with expression and
have that return the first failure.

### Loops and iterations

Unlike other programming languages there are no common for and do..while loops
instead we use good old recursion. Usually on production we tend to use
recursion sparingly since there are various abstractions set in place to do
more elegant and one liner solutions.

