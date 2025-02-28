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




























































