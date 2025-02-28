# Fault tolerance basics 

This is one of the core concepts of Elixir, i mean look at Erlang it was
developed with the purpose to have a reliable system that can operate even when
faced with run time errors.

The aim of fault tolerance is just that, to tolerate failure. This can be done
by acknowledging the existence of failures and minimizing their impact without
human intervention. We usually want to keep a pessimistic approach and treat as
if anything and everything can fail.

The goal is that regardless of what part of the system fails we can still
provide some sort of service without intervention.

Unsurprisingly a way to deal with error handling is through concurrency. If a
process crashes or anything goes wrong it will not crash any other process in a
sort of isolated way we can keep all the negative behavior away. 

## Runtime errors

### Error types

The BEAM distinguished 3 types of runtime errors:

- errors: raised by functions
- exits: used to deliberately terminate a process
- throws: allow non local returns (should be avoided as much as possible)

It is convention to use a `!` at the end of the function name if it can throw an
error.

### Handling errors

Main tool for intercepting run time errors is with the `try` expression.

```(elixir)
try do
...
catch error_type, error_value ->
...
end
```

It is worth noting that you can pattern match on the error_type and the
error_value and handle different types of errors differently.

If the error is not caught down the stack then the process terminates.

There is also an after block available that will be processes at the end of the
try catch block regardless of if an error was caught or not.

Unlike other common programming languages there is much less to do when catching
errors since the usual idiom is to let a process crash and then do something
about it.

Just like with IT most errors are one off issues that come from a corrupt state
and just letting the device crash and then restart usually solves the issue,
that is the same mentality behind the way errors are handled in elixir. Such
issues are considered part of the Heisenbug category.

## Errors in concurrent systems

Because processes share no memory, a crash in one process won't leave behind any
memory garbage or corrupt state. Therefore by running independent actions in
separate processes you automatically ensure isolation and protection.

### Linking processes

A basic primitive for detecting process crashes is the concept of links. If two
processes, and one terminates, the other process will receive and `:exit` signal
notifying that the process has crashed. One link connects exactly 2 process and
it is always bidirectional.

The crash of a single process will emit exit signals to all linked processes and
if the default behavior is not overridden then those processes with crash as
well.

**Trapping exits**

Usually you don't want the linked process to crash, you want that process to
know a spawned process crashed and then do something about it. To prevent a
crash from the linked process you can use the process flag to trap exits and
then use a receive to get the exit message and then do something about it while
still letting the linked process do its work. With this flag any exit messages
that get sent to a link will go to the message mailbox and can be treated with
a receive block.

### Monitors

Since links are bidirectional there are not always the answer. There may be
cases where you want a process A to know if B crashed but not the other way
around (unidirectional). In such cases you would use a monitor instead.

There are 2 main differences btwn monitors and links:

1. monitors are unidirectional, only the process that creates a monitor receives
notifications
2. the observer process won't crash when the monitored process terminates

**Exits are propagated through GenServer calls**

When you do a synchronous call request to a GenServer if the server process
crashes an exit signal will occur in your client process.

Internally GenServer sets up an internal monitor that targets the server
process.

Links, exit traps and monitors make it possible to detect errors in a concurrent
system. Tools that assist with error recovery in concurrent systems are known as
supervisors.

## Supervisors

A supervisor is a generic process that manages the life cycle of other processes
in a system. A supervisor can then start other processes, considered its
children. Using the techniques above it can detect when a child process
terminated and restart it.

Processes that aren't supervisors are called workers. These processes are the
ones that do the actual work requested. By running workers under a supervisor
you can ensure proper error handling of your processes and have them get
restarted after a crash. 

In order to use a supervisor you will need to create a process with spawn_link.
This is because if a supervisor is terminated it need to tell the children so
they can be terminated as well.

When using `Supervisor.start_link/2` the list of children is given along side a specification
that describes how the child should be started and managed.

The second argument in `Supervisor.start_link/2` is the strategy, also known as
the restart strategy (mandatory). Specifies how a supervisor should handle
termination of its children. For instance, one_for_one states if a child
terminates, another child should be started in its place.

Why should you use a named process for a Supervised process?

In order to be able to properly restart a process (its really just starting a
new process in place of the one that crashed) you need to be able not to rely on
the pid of the old process, since after the process is restarted all the old
references to the old pid are invalid. By using a named process you do not have to keep
track of the pid of the cache and you are able to freely restart the process.

### Child specification

To manage a child process a supervisor need to know the following:

- the way a process child should be started
- what should the child process terminate
- what term should be used to uniquely identify each child

When initialing Supervisor we pass in the list of child specifications and there
are some values there by default. If we keep using the default and refactor our
code in a way that breaks the function signature we would have to change the way
we call the Supervisor. Instead we can pass in a tuple in the child list
specification which will call `.child_spec(arg)` on the module passed in and
that way we just have to implement 1 function that can handle multiple cases.

GenServer by default already has a `child_spec(arg)` function so you don't
necessarily need to write one.

### Wrapping the supervisor

Just like with a GenServer it is advised to wrap the Supervisor in a module.
This module can usually be called `System` since it will be the interface that
starts up the entire system and the required workers/modules.

### Using a callback module

Another way of starting a supervisor is to use the module's init function. This
is similar to the way a GenServer is started. First you pass the `__MODULE__` to
`Supervisor.start_link/2` and then you define an `init/1` function in that
module which must return the list of child specifications and additional
supervisor options such as it s strategies (use `Supervisor.init/2`).

This is done in case you need more control since at first glance for simple
scenarios it achieves the same behavior. For instance if you need to do some
extra initialization before starting the system you can do it in `inti/1` or
since this is a little more flexible you can modify the list of children without
needing to restart the entire Supervisor.

### Linking all process

As of now the supervisor restarts the to-do cache and you get a new set of
processes, this includes all the other process that did not crash. This means
that once the cache process gets restarted the old process (for server and
database) are just unused garbage that are kept running.

You can double check this by looking at the number of processes being ran then
terminating the Todo.Cache service and starting the same Todo.Server that was
already started. You would have an extra process running (if it is a previously
started process then the cache should not have made a new process).

Terminating a Todo cache should also terminate its state in the proper way. To 
do this you must establish links between processes.

By linking every part of the system you get to detect an error from any part of
itself and then recover from it without leaving loaner processes behind.

Links ensure that dependent process are terminated as well, which keeps the
system consistent.

### Restart frequency

The supervisor will not restart a child process forever since there is s max
amount of tries per time period. By default the mac restart frequency is three
restarts in 5 seconds. This ofc is just the default and can be changed by
passing `:max_restarts` and `:max_seconds` as options to the
`Supervisor.start_link/2`.

After the max restart frequency is exceeded then the supervisor will terminate
as well as all its children.

This is simply because if restarting the process does not help the crashing
issues then there is no point in infinitely restarting a process.























































