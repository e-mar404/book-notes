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

### Writing tests

The testing framework for elixir is ex_unit and it is already included in the
elixir distribution.

The file structure is very similar to how it is for lib modules but with a
_test at the end of the file name. 

This is very similar to any other test framework (most notably the unit
frameworks ofc). Look at documentation for help.

### Analyzing process dependencies

At the moment the is a single cache process that handles all the user requests
to get their proper todo server pid. This could be a bottle neck since there is
only one cache instance which means that there is only one request at a time.
Because each request does not take a long time we are okay to just leave it like
this since the number or request would not be that much lower.
 
Usually it is good enough if a single process can handle enough requests at the
same rate as they are coming in. If the handling rates are slower than the
incoming requests rates then that's when you look at optimizing the server
process or looking at concurrency.

If you need to make sure part of the code is synchronized it is best to run that
code in its own dedicated process.

## Persisting data

Extended code will go on persistable_todo_cache

### Encoding and persisting

In order to save something to disk you can encode a structure to binary and save
that to the disk and at a later point it can be decoded and transformed to a
structure in our program.

In order to implement a database we will create GenServer with two requests
store and get. When storing it will create a file with the key name, and the
contents will be the Elrang term. This way we can store thing to persistent data
disk.

We use an attribute to set the folder path for the persisting data. This is a
pretty simple approach but it works.

Look at the implementation in `persistable_todo_cache/lib/todo/database.ex`.
 
### Using the database

In order to start the database when the application starts we need to add it to
the init function in Todo.Cache.

**Storing the data store request**

To persist the list data we will have to call the database from the Todo.Server.

**Reading the data**

To read the data at the start of the server is to get that data on the init
callback of the server. You should be careful about it since a long running init
callback block the GenServer.start function.

In order to address this GenServer gives you an option to solve this by allowing
you to split the initialization into two phases: one that blocks the client
process and another one that can be performed after the GenServer.start
invocation in the client has finished.

### Analyzing the system

As of now the database can get processes that take a long time since there is
only one db process and it deals with IO which is an inherently concurrent
problem with its own bottlenecks and other blockages.

Look at how an entry is stored it may not look problematic at first glance but
because it is asynchronous and if by any chance the db gets more requests faster
than it can handle then the db's message mailbox will be ever increasing,
consuming memory.

The get request form the database is not safe from bottlenecks either, since it
is a synchronous request the db instance cannot receive any other messages while
it is working on that request.

### Addressing the process bottleneck

**Bypassing the process**

The simplest way is to just by pass the process. Really identify if a process
really needs to be one or if you can get by with just using a module.

Usually you should only use processes if:

- the code must manage a state
- the code handles a resource that can and should be reused between multiple
  invocations
- critical section of the code must be synchronized

**Handling requests concurrently**

Another more complicated option is to have workers spawn out and do the job of
the process but divided. We can use this for the db. This is useful when
requests depend on a common state but can be handled independently.

**Limiting concurrency with pooling**

In order to deal with an mailbox overflow you can create an pool of available
server process and when a request arrives it will delegate the message to one of
the pooled workers.

This technique keeps concurrency from getting out of control and it is very
helpful when the process does not have a good way to deal with resources that
can't handle unbound concurrency.

It is important to remember that if a computation can be ran in parallel, you
should consider running them in separate processes. In contrast if an operation
must be synchronized then you'll want to run it in a single process.

For the sake of learning this is kind of a reinventing the wheel but in
production systems you should just use a third-party already well tested solution
like Poolboy with Ecto.

#### Exercise: Pooling and synchronizing

Now, it’s time for you to practice a bit. This exercise introduces pooling and 
makes the database internally delegate to three workers that perform the actual
database operations. Moreover, there should be per-key (to-do list name) 
synchronization on the database level. Data with the same key should always be 
treated by the same worker.

Here are some pointers for doing this:

- Start with the existing solution, and migrate it gradually. Of the existing 
code, the only thing that needs to change is the Todo.Database implementation. 
You don’t have to touch any of the other modules.

- Introduce a Todo.DatabaseWorker module. It will be almost a copy of the 
current Todo.Database, but the process must not be registered under a name 
because you need to run multiple instances.

- Todo.DatabaseWorker.start should receive the database folder as its argument 
and pass it as the second argument to GenServer.start/2. This argument is 
received in the init/1 callback, and it should be stored in the worker state.

- Todo.Database will receive a significant rewrite, but its interface must 
remain the same. This means it still implements a locally registered process 
that’s used via the functions start/0, get/1, and store/2.

- During the Todo.Database initialization, start three workers and store their 
PIDs in a map, using zero-based indexes as keys.

- In Todo.Database, implement a single request, choose_worker, that will return
a worker’s PID for a given key choose_worker should always return the same 
worker for the same key. The easiest way to do this is to compute the key’s 
numerical hash and normalize it to fall in the range [0, 2]. This can be done 
by calling :erlang.phash2(key, 3).

- The interface functions get and store of Todo.Database internally call 
choose_worker to obtain the worker’s PID and then forward to interface 
functions of DatabaseWorker, using the obtained PID as the first argument.

- Always try to work in small steps, and test as often as possible. For example,
once you implement Todo.DatabaseWorker, you can immediately start iex -S mix 
and try it in isolation.


## Reasoning with processes

A server process can have 2 different perspectives, on one hand (inside pov) it can be a
sequential program that accepts and handles requests and optionally handling
some state. On the other (outside pov) it is a concurrent agent that exposes a well defined
interface.

Processes are mostly independent but when communication is needed you can use
casts and calls. 

Casts (pros & cons):

pro: promote system responsiveness
con: at the cost of reduced consistency

Calls (pros & cons):

pro: promote consistency
con: reduce system responsiveness

Usually better to start with a call and if you notice bad performance move over
to a cast.
