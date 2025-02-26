defmodule Todo.Server do
  use GenServer

  def start do
    GenServer.start(__MODULE__, nil)
  end

  def add_entry(todo_pid, new_entry) do
    GenServer.cast(todo_pid, {:add_entry, new_entry})  
  end

  def entries(todo_pid, date) do
    GenServer.call(todo_pid, {:entries, date})  
  end

  @impl GenServer
  def init(_) do
    {:ok, Todo.List.new()}
  end

  @impl GenServer
  def handle_cast({:add_entry, new_entry}, list) do
    {:noreply, Todo.List.add_entry(list, new_entry)}
  end

  @impl GenServer
  def handle_call({:entries, date}, _, list) do
    {:reply, Todo.List.entries(list, date), list}
  end
end

