# Data Abstractions

Elixir being a functional language it promotes decoupling of data from the
code. Instead of classes, you use modules, which are collections of functions.

The important thing to notice in Elixir is that a module is used as the
abstraction over the data type. Each module has two type of functions modifier
(the ones that transform the data) and query functions (the ones that return
some piece of information from the data).

### Note on module creation

Most functions can be queried because they all follow a simple rule, the data
type that is abstracted with the module is the first argument in every
function.

### Basic Abstraction

Build a module that abstracts away the task of a to do list, the requirements
are the following:

- create a new to-do list
- add new entries to the list
- query the list

### Composing abstractions 
 
Nothing stops you from using an abstraction on top of another abstractions. For
the next exercise look at how we use the map to have multiple values associated
to the same key (day) and implement a MultiDict abstraction under the TodoList.

### Structuring data with maps

The way the todo list module is set right now with every new field that is added
it will break the interface that all the clients rely on. To address this we can
use maps and only pass one entry instance with all the fields necessary.

After getting entries data to be a map the TodoList is a lot more extensible and
better equipped to handle new features.

Something that does come to mind is that as of now an instance of a TodoList is
no different from a map (to the runtime) and there might be some times that you
want to enforce a more granular control on the structure definition and this is
where structs come in.

### Abstracting data with structs

Elixir provides a facility called structs, which allows you to specify the
abstraction structure up front and bind it to a module. Each module can define
only one struct which can then be used to crease new instances and pattern match
on them.

Because you can pattern match on structs you can try to pattern match against a
map and you'll see that it does not match with a map solving out previous
concern.

Structs are created at compile time to the Elixir compiler makes it possible to
catch some errors like creating a struct with a non existing field.

### Records

This  is a feature that lets you use tuples and still be able to access
individual elements by name.

Records are a little faster than maps but by a negligible amount. They are
present mostly for historical reasons since Erlang is the one that heavily uses
records so if you need to use an Erlang library then you'll have to define and
import the records from that library.

### Data transparency

Its important that data in Elixir is always transparent. Clients can read any
info from your structs and any other data type and there is no easy way of
preventing this.

For each abstraction you build you can override the behavior of the IO.inspect/1
function to show whatever you may want to show. This function prints the
inspected representation of a structure to the screen and returns the structure
itself.

### Look at new crud_todo implementation

It has some important aspects on using structs and an exercise to delete a
task.

*Exercise* 

Extend the todo_crud file to include a new module to import from a csv

### Polymorphism with protocols

Polymorphism is a runtime decision about which code to execute, based on the
nature of the input data. In elixir, the basic (but not only way) to do this is
with protocols.

So far we have seem Enum functions deal with different data types, and they have
done different things based on the type that they are enumerating/iterating
over.

### Protocol basics

A protocol is a module in which you declare functions without implementing them. 
This will act as a contract that needs to be followed to act as the interface to
deal with wtv thing you are trying to make.

The behavior of to_string/1 is exactly the same as that of
String.Chars.to_string/1. That is because Kernel.to_string/1 delegates to the
String.Chars implementation.

### Implementing a protocol

look at todo_to_string.exs for the implementation of to_string for the module
TodoList.

Its important to notice that the protocol implementation doesn't need to be part
of any module. This has powerful consequences. You can implement a protocol for
a type, even if you can't modify the type's source code or you can place the
protocol implementation anywhere in your own code, and the runtime will be able
to take advantage of it.

### Built-in protocol

Some other really useful builtin protocols are:

- Inspect: lets you control how your structure is printed in the debug output
- Enumerable: lets you use Enum and Struct functions to iterate through your
  data structure
- Collectable: closely related to Enumerable and lets you have a structure that
  can repeatedly add elements to

