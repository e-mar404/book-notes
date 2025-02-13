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

*Iterating with recursion*

When wanting to implement a function that prints all natural numbers we can make
a function that calls (n-1) and then prints (n) the way that the recursive stack
gets called will make it look like it starts at 1..n.

Exercise. Extend this to make it work for negative numbers

```elixir
defmodule NaturalNums do 
    def print(1), do: IO.puts(1)

    def print(n) do
        print(n-1)
        IO.puts(n)
    end
end
```

Extended function: adding these multi clause functions will add the ability to
print the negative natural numbers from 0..n 

```elixir
def print(0), do: IO.puts(0)

def print(n) when n < 0 do
    print(n+1)
    IO.puts(n)
end
```

In order to successfully iterate with recursion you first set your goal state
with multi clause functions and then the body of the other functions will be the
general work that needs to be done to reach the end/goal state.
 
### Tail Call Optimization (TCO)

Usually doing recursive calls like this will add functions to the call stack and
at some point there will be a stack overflow and the program will crash. To
remedy that Erlang can handle optimization in a very special case to where if
the last thing a functions executes is a call to another function then it will
act like a goto/jump statement and will not take more space in memory.

Because tail recursion does not consume additional memory, it is an appropriate
solution for arbitrarily large iterations.

You can also think of tco as a direct equivalent of a classical loop in
imperative language.

Even with this said tco is not always the answer, rule of thumb is that if the
loop needs to run for a long time (big recursive stack) then go with tco if not
then just whatever is more readable and easier to grasp.

*Practice tco*

Implement the following: first non-tail recursive then tail recursive

- list_len/1 return the length of the list
- range/2 take two integers from and to and returns a list of all integer
  numbers in the given range
- positive/1 take a list and returns another list that contains only the
  positive numbers form the input list

### Higher order functions

A higher order function is a type of function that take s one or more functions
as input or returns one or more functions (or both).

For now you just need to know that Enums are a type of data that implement a
specific Enumarable contract. Some examples are ranges, lists, maps, and MapSet.

Good tip when writing unctions for Enum functions is to use the capture
operator & for simplified lambda functions.

The most versatile function might be reduce since you would make the main higher
order functions from functional languages with reduce (map, filter, reduce).

As a tip from the book, avoid writing complex lambdas, that is probably a sign
to take the lambda out and make it its own function.





