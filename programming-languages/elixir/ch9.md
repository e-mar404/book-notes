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

## Starting processes dynamically

### Registering to-do servers

In order to do this is it pretty similar to the process applied to the database.
You need to register the process and use the function `via_tuple/1` of the
`Todo.ProcessRegistry` module to avoid collisions.

### Dynamic supervision

Unlike the database the to-do servers do not need to be always persistent with
the same amount, we want a dynamic number of to-do servers running that get
created when calling `Todo.Cache.server_process/1`. 

Since you don't know the number of children you can't start a supervisor process
with any number of children upfront since you won't know the number. For this
Elixir provides `DynamicSupervisor` module.

The DynamicSupervisor is very similar to a regular supervisor but instead of
preemptively starting supervised child processes you get to start them on demand
with `start_child/2`.

### Finding to-do servers

Since the `Todo.Server` module was turned into a dynamic supervisor it is a lot
easier to keep track of the running todo servers. In order to start one you just
add the server module as a child spec when using
`DynamicSupervisor.start_child/2` and then use the return values from that
function to determine if the server has stared or not. In the case of this to-do
app it doesn't matter to us either way since we just want the pid that it
returns, (which it does in both scenarios).

The way that the server_process is set up as of now means that it will perform
serialized actions which means there won't be a race condition but it is
possible to bottleneck the Supervisor that server_process is calling on every
call to that function. There is a better way to do this with distributed
registration but that is a topic for later.

### Using the temporary restart strategy

If a to-do server crashes then there is no need to automatically restart it
since it will come back up dynamically next time that it is used.

### Testing the system

To test that this implementation works:

1. start the whole system
2. get one to-do server
3. repeat the request, making sure it doesn't start another server
4. get a different to-do server, it should start a new server
5. crash one to-do server
6. try to get that same to-do server, the pid should be different

## Let it crash

In general, complex systems should employ supervisors as their from of error
handling. OTP provides logging facilities, so process crashes are logged and you
can see that something went wrong. It is even possible to set up an event
handler that can catch crashes and send email notifications or messages to other
systems.

An important consequence is that this style of programming moves away from the
defensive style of try catch blocks. This style is very clearly known as the
"let it crash" approach, which is worth nothing not everything should crash.
Notably 2 errors should always be caught:

1. critical processes that shouldn't crash
2. when you expect an error that can be dealt in a meaningful way

### Processes that shouldn't crash

These process that shouldn't crash are considered system's error kernel
processes. These are the process that if they crash they take out the whole
application.

Usually we want to keep these processes as simple as possible, since the less
logic there is the less chance there is for failure.

If the services need to be a little more complex then it is worth separating
them into two modules/services/processes: one that handles the state and the
other that handles the logic. It is also a good idea to have try catch blocks in
the module that handles the state since this will keep it from crashing.

### Handling expected errors

If you can predict and you have a way to deal with it then there is no need to
crash the process. This is similar to how you can catch the errors of reading a
file or reading from thing that throws errors.

You can pattern match the errors and responses that you have a plan for and if
there is not a match then there will be a pattern match error for something you
don't have planned for so it is expected to crash based on the "let it crash"
ideology.

### Preserving the state

Elixir does not provide an implementation for restoring state after a process
crashed, that is a task that you have to implement yourself (usually saved in
another process or in a db, and then restored when you restart).

This can have its own negative effect, specially if the process is crashing due
to the state having inconsistent data or a bug which causes a transformation to
change. You should be careful when persisting state and should try to avoid so
if possible.



































