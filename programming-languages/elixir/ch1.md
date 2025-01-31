# First Steps

### What is Erlang?

A functional language that prioritizes scalability, fault-tolerance, distribution of systems and concurrency. 
It runs on the BEAM VM and has a plethora of tooling that makes the dev environment very easy to test and deploy.
Can create thousands/millions of processes (they are BEAM processes not OS processes like pthreads for C or goroutines for go).

### Where is Erlang being used?

In highly concurrent systems that need to be up and running all the time even when services fail and software updates are in progress. The Erlang system of concurrency was first invented for the telecommunication domain but it has made its way to highly concurrent distributes systems like social media, banking and messaging.

Currently it is being used by Whatsapp, Discord and RabbitMQ.

### Pros & Cons of Erlang

Pros:

- Fault tolerant
- Scalability
- Distribution
- Responsiveness
- Live updating

Cons:

### How can BEAM machine create and run so many processes?

The BEAM VM is in itself an operating system that has its own scheduler (round robin) and will pass on a process to any free CPU core. This unlocks the ability to create a lot more processes than CPU cores. The lack of shared state makes this possible since the CPU core can be working on a single process and change to a different process with no performance overhead of maintaining shared state between processes.

### How is Erlang different from microservices?

Similar to Erlang, microservices let you split different services this gives fairly controlled handling of errors providing fault tolerance and since they are different services you can spread them out across machines which will lower the risk of hardware failure taking down the entire application.

Where they differ is the ease of spawning a great number of these "services/processes", Erlang has much more "affordable" scaling which would make a task like: having a process handle online video game instance per player as well as per game. With OS threads/processes the managing of such instances would be a lot more broad like having a single instance managing multiple activities.

Where microsystems show their strengths over Erlang is on the deployment ecosystem with technologies such as Docker. It is a lot easier to deploy, horizontally scale and get coarse-grind fault tolerance with microsystems (even though you can achieve this with only the BEAM VM)

### What is the difference between Elixir and Erlang?

Elixir has language features that minimize some of the code noise and ceremony that happens in Erlang. A quick example is generating a simple genserver.

A major difference between them is that Elixir implements macros. Macros is code that runs at compile time (not like c-style macros). This lets Elixir be built on-top of Erlang and written in mostly Elixir. Macros are super powerful and extensible letting you have more flexible and less ceremonious code.

Elixir emphasizes the use of the |> operator to compose functions.

### When should you consider something else?

Since Elixir runs on a VM (BEAM) it is not necessarily the fastest to start up or in raw performance. Good performance comes from the concurrency model, fault-tolerance and scalability. If the system that is being designed does not need to be running the entire time and it requires really really fast performance sparingly (not something that stays on all the time, but something that requires a fast startup time), then you should look at something else.

"the goal is not to serve the most request per second, it is to reliably serve requests"

Another limitation is the CPU limitations, if the system has a lot of CPU intensive tasks then it is better to go with something else.
