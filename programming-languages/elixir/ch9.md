# Isolating error effects

The main idea of this error handling and fault tolerance in Erlang/Elixir is
that if you are able to confine an error's impact to a small part of the system,
your system can provide the most of its services at all time.

## Supervision trees

### Separating loosely dependent parts

If you only have one supervisor that is at the top level then any time a process
is restarted that has some amount of workers then it will restart all the
workers instead of just the one that failed. This coarse-grained approach can
create unnecessary workload but it it a lot easier to start. To reduce error
effect, you need to start individual workers through the supervisor.

In order to get this fine-grained control you need to pass over the other
process in the child specification list. This will have both children be
supervised and isolated.

Coarse-grained:

Supervisor ->starts-> Process A ->starts-> Process B

Fine-grained:

Process B <-starts<- Supervisor ->starts-> Process A

We change the flow of staring process so instead of having A be the parent
process that starts B you get the Supervisor to start both (set through the
child specification).

The children are started synchronously in the order specified. The next child is
started only after the `init/1` callback function for the current child is
finished. Which is why we don't want the start function to run for a long time
since it would block the start up time of any other child. We use continues to
deal with long start up times in an asynchronous way.

### Rich process discovery

Now with the approach above, if any of the database workers crash the entire
pool of database workers will restart and ideally we want to only restart the
process that crash, since there is no need to restart properly behaved
processes. In order to do that we would have to have each of the database
workers be under supervision.

There is just one problem with this at first sight. If you have a supervisor
start the database workers the same way that we have started the database and
cache processes the database will not have access to the pid pool since the
supervisor doesn't expose those pid's since they change as they get restarted.
 
The way that we have gone about something like this is to register the process
via a name (an atom) to be able to identify them without their pid, but since
the database worker is a singular template process we would not be able to have
the name be the module name or an atom at that, we need it to be something more
complex. This is where a process registry comes in, which will maintain a
key-value map where the keys are the names of the process and the value is the
pid.  

The general way that this would work is by having the worker process register
itself, usually during initialization. At some point later the client will query
for that process (using the complex alias) and the server (process registry)
will respond with the appropriate pid.

Elixir already comes with a `Registry` module in its standard library for such
cases.

A very useful property of Registry is that it links itself to the processes so
it is able to tell when they terminate and remove the registry entry
accordingly.

The implementation is written in plain elixir and heavily uses the ETS table
feature with will make for really performant parallel code, which means there is
usually not any blocks in processes and it is very salable.

### Via tuples

A via tuple is a mechanism that allows you to use an arbitrary third-party
registry to register OTP compliant process, such as GenServer and supervisors.

A via tuple has this shape: `{:via, some_module, some_arg}`.

- some_module: acts like a custom third-party process registry, and the via 
tuple is the way of connecting such a registry with GenServer and similar OTP
abstractions
- some_arg: specifies how the process should be looked up based on the
  implementation of some_module

In the case of `Registry` it will look something like this: `{:via, Registry,
{registry_name, process_key}}`.

### Registering database workers

When creating a process registry process that is going to be supervise it is
important to remember that if you don't use GenServer as the base implementation
then you need to provide a `child_spec/1` function that will be used for the
supervisor to start the process. On the other process we have not had to worry 
about this because GenServer already has a function implemented for it.

### Supervising database workers

Now it is time to move the database workers to their own supervisor. This
because if you put too many process under the same supervisor you are more
likely to reach the max restart frequency unnecessarily quick potentially
causing more issues.

In some cases, if the situation is just right and it is possible for a database
worker lookup to return an invalid value, this happens if the db worker crashes
shortly after the client process found its pid but before the request is sent.
For a brief moment some part of the system might not be in a consistent state,
but the way that a supervisor will restart process that crash at some point it
will be back to normal.

### Organizing the supervision tree

Although supervisors are frequently mentioned in the context of fault tolerance
and error recovery, defining the proper starting order is their most essential
role. The fact that they are good for that is a side effect of having a good
supervision tree in place.

In supervision trees you start by handing the error as locally as possible and
if that doesn't work keep getting wider and wider in scope until, either, the
error is resolved or the entire application crashes.

**OPT compliant processes**

All processes started from a supervisor should be OTP compliant. To see what
that means go to [Erlang
documentation](https://www.erlang.org/doc/design_principles/spec_proc.html#special-processes)

Elixir provides various implementations of OTP compliant processes (GenServer,
Supervisor, Registry, Task, Agent, etc). So you should try to avoid spawning
processes your self.

**Shutting down processes**

An important benefit of supervision trees is the ability to terminate process in
a controlled way. You get to choose how the process should terminate, how long a
supervisor should wait for the termination to complete and much more.

**Avoiding process restart**

There are cases like with an HTTP or TCP connection that if a process fails the
other party is also closed/disconnect so at that point there is not case in
restarting the process. For this you can set the restart behavior with: 

- restart: :temporary -> the worker isn't restarted on termination
- restart: :transient -> the worker is restarted only if terminated abnormally.

**Restart strategies**

These are the restart strategies:

- :one_for_one -> terminations are handled by starting a new process in its
  place, leaving another children alone
- :one_for_all -> if a child crashed, the supervisor terminates all other
  children and then restarts them
- :rest_for_one -> when a child crashes, the supervisor terminates all younger
  siblings of the crashed child then starts a new child process in its place

The last 2 strategies are useful if there's tight coupling between children
processes. One example is when a process keeps the pid of some sibling in its
own state.









































