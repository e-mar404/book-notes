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









































