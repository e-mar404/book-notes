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

## Creating a process

To create a process, you use the auto imported spawn/1 function. This function
creates a new process that will run the lambda passed on to it.

It also returns a PID that is used as an identifier and can be used to 
communicated with a process while it is executing.

When data is passed from a function to a spawn lambda the data that gets passed
will have a deep copy, this is because two functions/processes cannot have
shared data (immutability). When doing this processes can run concurrently, but
will not have deterministic execution (can return in any order).
 
Sometimes you don't just want to do a fire and forget approach to concurrency
spawning process. Sometimes you want to return the result of the concurrent
operation to the caller process. For this purpose, you can use message passing.

## Message passing

When wanting to communicate between processes you can do message passing. Each
process has a mailbox that can be accessed via the PID of the process. Remember
since the processes cant share memory they will have to be deep copied. Each
mailbox is treated in a FIFO queue limited only by the available memory. The
receiver consumes messages in the order received, and a message can be removed
from the queue only if it's consumed.

To get the PID it will be either returned through spawn/1 or you can call it via
the auto imported self/0 to get the PID of the current process.

To send messages use the function send/2 in the Kernel module. And on the other
end to receive and process a message you need a receive block in that process.

It is possible to use pattern matching to do a specific action based on the
structure of the message. Like if you receive {:message_one, _} you can execute
something different than receiving {:message_two, _}.

There are some potential issues with this that can cause the shell to wait
indefinitely and have to be manually terminated: 

- one of them is if the mailbox of a process is empty and you declare a receive
  block. Since the mailbox is empty it will just wait until a message gets
  there, but because it is waiting you cant send a new message therefore
  blocking your current shell
- the other way is if the receive block does not have a matching pattern to the
  message receive, nothing will be returned so the receive block will just block
  the shell

To mediate this you can add an after block after the receive to be executed
after a certain time if the receive block does not receive a message in a
specified allotted time.

### Receive behavior

If a message does not match any of the patterns in the receive block it just
gets put back in the message queue and gets the next message.

Just like everything else in elixir the receive block also returns a value that
can be referenced later or even patterned matched on.

### Synchronous sending

Usually the most basic type of concurrency is firing up a process and just
letting it run not caring about the result or bothering to do message passing
just forgetting afterwards. But sometimes a caller needs some kind of response
form the receiver. There's no special supported way of doing this. Instead you
must program the logic into your into both parties.

It is important to note that if you call self/0 on the spawn lambda function
definition then that will be the PID of the spawned process and not the one of
the caller. To be able to return messages to the parent caller you need to make
a variable that calls self/0 outside of the spawn closure.

## Stateful server processes

In Elixir, it's common to create long-running processes that can serve various
requests, such processes may maintain some internal state-an arbitrary piece of
data that may change over time. This is called a stateful server process.

### Server process

A server process is an informal name for a process that runs for a long time,
and can handle various requests (messages). In order to do this you need to use
tail recursion. It is important to note that having an infinite loop that is
just waiting for a message does not consume endless cpu cycles since this
process gets put in a suspended state while waiting for a message.

*GenServer*

As the case with regular loops we do not need to always implement the recursive
loop that a server would run. We get an abstraction called GenServer to
partially implement this for us, then we just need to add our logic to the
partial implementation for it to work.

When making a server you should not make the client care about how to call the
server you should just provide an interface that takes in the server pid and
what needs to be done. The way to communicate with the server should be
abstracted in the server so the client can only call one function and something
happens.

### Server processes are sequential

Its important to realize that a server process is internally sequential. It runs
a loop that processes one message at a time. This, if you issue 5 async query
requests to a single server process, they will be handled one by one and the
result of the last query will take the longest.

Having a single server that can process something we can create a pool of
servers and then give a task to one of them. There are various ways to do this
but the simplest one is to have a list of sever pids. (not efficient since it
would take O(n) to randomly access a server pid, it would be better to use a map
or a round robin approach)

## Keeping a process state

Server processes open the possibility of keeping some kind of process-specific
state. 

One way to do that is to pass the state to the recursive loop of the server.
This can be anything, a rand variable or a even a saved state.

## Mutable state

Most common technique to keep a state that changes based on the message received
is to have a receive block before firing up a loop process and pass it the new
state based on the message received.

Trying this with calculator.ex

As you introduce multiple requests to your server, the loop function becomes
more and more complex. If you handle too many request, it will become bloated,
turning into a huge switch/case-like expression.

You can refactor this to rely with pattern matching instead and move message
handling to different functions.

