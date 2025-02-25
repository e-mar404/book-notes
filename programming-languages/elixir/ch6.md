# Generic server process

Erlang already provides an abstraction module for implementing server process
via the OTP. The module is GenServer.

## Building a generic server process

All code that implements a server should include the following:

- span a separate process
- run an infinite loop
- maintain the process state
- react to messages
- send a response back to the caller

### Plugging in with modules

To keep thinks independent there will be two implementations a generic
implementation and then a more specific and concrete implementation. The generic
code will spawn a process and a loop but is is up to the concrete implementation
to determine what is going to happen in the loop / processes spawning.

The simplest way to keep the generic code steering the wheel while the specific
implementation fills in the details is by the use of modules.

### Implementing the generic code

see server_process.ex

The way that we approach this problem will be by: 

1. make the generic code accept a plugin module as the argument that will act as
   a callback to the specific functionality
2. maintain the module atom as part of the process state
3. invoke callback module functions when needed

### Using the generic abstraction

see server_process.ex

To test the generic implementation of the server we will implement a simple key
value store.

The callback module that we use will need to implement 2 different functions
init/0 that is called when we start the server and handle_call/2 which is called
during the loop after a call is places on the server.

Because the infinite loop is already implemented on the ServerProcess module
then the KeyValueStore can focus on implementation making it a lot shorter,
concise and easy to understand.

It is beneficial to make clients completely unaware that they are interacting
with the generic server process which can be achieved by adding some helper
functions to the specific implementation module.

### Supporting asynchronous requests

In some cases you want to just sent a message or command to the server and not
have to wait for a response. For these async messages and tasks we use cast (OTP
convention). The general server process has both of these so it is good to
determine how you need to implement each. 

#### Exercise: Refactor the todo server

Take the complete code form todo server and adapt the latest version of the
server process module on the new todo server.

What has been implemented here is the basic gen server abstraction the OTP
version has a lot more functionality but this is a quick and mainly complete
cover of the abstraction.

## Using GenServer

When shipping productions code you dont want to be maintaining and building your
manual implementation of a generic server for this reason Elixir provides an
already tested implementation with the GenServer module. This module covers edge
cases and includes the following:

- support for calls and casts
- customizable timeouts for call requests
- propagation of server process crashed to client processes waiting for a
  response
- support for distributed systems

### OTP behaviours 

In Erlang, a behaviour is generic code that implements a common pattern. The
generic logic is exposed through the behaviour module, and you can plug ino it
by implementing a corresponding callback module that implements the necessary
functions. 

There is also a way to check that a callback module implements such functions at
compilation time.

The Erlang std provides the following behaviours: 

- gen_server--Generic implementation of a stateful server
- supervisor--provides error handling and recovery in concurrent systems
- application--generic implementation of components and libraries
- gen_event--provides event-handling support
- gen_statem--runs a finite state machine in a stateful server process

### Plugging into GenServer

The GenServer behaviour defines eight callback functions, but only a subset of
those are often used.

To use a behaviour you need to use the use keyword which it will in turn inject
a bunch of functions that will need to be implemented.

In order to check what functions a module exports you can use the automatically
injected function that every module in elixir has, \_\_info\_\_/2.

### Handling requests

Lets look at 3 of the interface callbacks that need to be implemented for
KeyValueStore in GenServer.

1. init/1, the argument is the same one passed on to
   GenServer.start(callback_module, opt). init must return {:ok, initial_state}
2. handle_cast/2, accepts requests and state and should return {:noreply,
   new_state} 
3. handle_call/3, accepts request, caller info and state. Should return {:reply,
   response, new_state}

It is important to notice that GenServer.start/2 only runs after init/1 callback
is complete. The client process that starts the server is blocked until the
server process is initialized.

Also if a call doesn't receive a message within 5 seconds a timeout will be
raised. This can be overridden by using GenServer.call(pid, request, timeout)
function instead.

### Handling plain messages

Just like when we made our own handle_call and handle_cast functions we sent
other info to through message passing. GenServer does the same thing by tagging
such messages, but when we need to handle something ourselves and that does not
fall under the rule of the GenServer we can send out own messages and have them
handled through the handle_info/2 function.

### Other GenServer features

When implementing functions for the behaviour of GenServer it is common and best
practice to use the decorator `@impl GenServer` since this will give us a
warning during compile time if we did not correctly implement a function from
the interface.

**Name Registration**

You can also pass a name to register your server instance to call it without a
pid by passing a name: name parameter to `GenServer.start`.

The usual convention is to use the module name since that is already an atom and
it is the safest thing to do since there won't be name collisions.

**Stopping the server**

There are multiple atoms that can be used as responses from handle_* calls such
as:

- :ok, initial_state
- :reply, response, new_state
- :noreply, new_state
- :stop, reason (should be returned when there is an error related reason)
- :stop, reason, new_state (same thing as before but for handle_*)
- :stop, reason, response, new_state
- :normal
- :ignore (should be returned when it is an intended stop)

### Process life cycle

Very similar to the actor model. An actor is a concurrent computational entity
that encapsulates state and can communicate with other actors. In the context of
Erlang, an actor is a GenServer process.

This was coincidental and authors of Erlang did not find out about the actor
model until way later.

### OTP compliant process

Once you are in production you don't want to be breaking conventions and one
important rule to always follow is to have all processes be OTP-compliant. This
means that the processes created should be able to be used in supervision trees
and errors in those processes are logged in detail. This means that you should
not just go off and implement everything with `spawn`.

There are various modules that are both included in the Elixir std and third
party ones, some are:

- Task--run one off jobs that process some input and then stop
- Agent--appropriate if sole purpose of the process is to manage and expose
  state
- Phoenix.Channel--module from the Phoenix web framework used to facilitate 2
  way communication between a client and a web server over protocols like web
  sockets and http

There are still much more modules that are OTP compliant and that are very
useful. It is worth noting that all of these (with exception of Task) are built
on top of GenServer, so having a good fundamental with GenServer is a good
building block.

## Exercise: GenServer-powered to-do server

Use GenServer in the implementation of the todo server in file todo_server.ex
