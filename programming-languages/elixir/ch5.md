# Concurrency Primitives

## Concurrency in BEAM

Erlang is all about writing programs that are highly available and always there
to respond meaningfully. In order to that we should tackle the following:

- Fault tolerance: minimize, isolate, and recover from the effects of run-time
  errors
- Scalability: Handle a load increase by adding more hardware resources without
  changing or redeploying the code
- Distribution: Run your system on multiple machines so that others can take
  over if one machine crashes

In the BEAM the unit of concurrency is a process. This is not the same as an OS
process, BEAM processes are much lighter and cheaper than an OS process.

Really big example that the BEAM avoids is the scenario where one task is taking
too long to complete and that one single request blocks all other pending
requests.   

### Why can crashing tasks be bad

If a task/request crashes we don't want that task to have an unhandled exception
in one handler to crash another handler, or even less the server. You also don't
want to leave an inconsistent memory state laying around (fp helps a lot with
this).

In BEAM, a process is a concurrent thread of execution. Unlike OS processes or
threads, BEAM processes are lightweight, concurrent entities handled by the VM,
which uses its own scheduler to manage their concurrent execution. (By default,
BEAM uses as many schedulers as there are CPU cores available.

By using a dedicated process for each task, you can take advantage of all
available CPU cores and parallelize the work as much as possible.

Finally, each process can also send message to another or even manage some
state. This is possible because of the data immutability of Elixir.

## Working with processes

It is important to realize that concurrency does not mean parallelism.
Concurrency means that the programs have their own independent execution
context. For the programs to be parallel they should be ran at the same time in
2 different threads. Concurrency does not always speed things up.
