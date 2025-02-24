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
