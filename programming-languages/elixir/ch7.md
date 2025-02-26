# Building a concurrent system
 
It is not uncommon for a moderately complex system to have a few thousand
process and a more complex system to have a couple hundred thousand or even
millions of processes. 

The ultimate goal that will be reached by the end of the book is to build a
distributed HTTP server that handles multiple users who are simultaneously
manipulating multiple todo lists.

## Working with the Mix project

Elixir comes with the Mix tool that helps with compiling, testing and organizing
code.

You can start the interactive shell with a mix project with `iex -S mix`

There are usually no hard rules when dealing with naming and organization of
files under the lib dir but there are a few conventions: 

- place modules under a common top level alias
- one file per module (exceptions can happen with small modules that are only
  used internally, think protocols)
- filename should be underscored and in snake case of the module name
- folder structure should correspond to multipart module names

## Managing multiple todo lists

So far we have implemented a pure functional Todo.List and a Todo.Server that
can be used to manage one todo list for a long time.

There are two was to extend the todo list code further to handle multiple lists:

1. implement a pure functional abstraction to work with multiple todo lists and
   modify the server to handle these multiple lists
2. run one instance of existing todo servers for each todo list

The problem with the first approach is that there will only be one process to
serve all users. With the second approach you can use as many processes as there
are users which is a lot more concurrent and scalable.

In order to do this there will be another abstraction, one that will cache
multiple server pids and their state and return an available server (or create
one if needed).

### Implementing a cache

In order to implement a cache we need to use a GenServer implementation which
keeps the sate of the running servers and the name given to them. The name will
be used as the identification for each user's list name. This will be stored in
a map and will have similar state flow to that which we have been doing
recently.


