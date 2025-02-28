defmodule Todo.Server do
  use GenServer

  def start_link(list_name \\ nil) do
    GenServer.start_link(__MODULE__, list_name)
  end

  def add_entry(todo_pid, new_entry) do
    GenServer.cast(todo_pid, {:add_entry, new_entry})  
  end

  def entries(todo_pid, date) do
    GenServer.call(todo_pid, {:entries, date})  
  end

  @impl GenServer
  def init(list_name) do
    IO.puts "Starting to-do server for #{list_name}"
    {:ok, {list_name, nil}, {:continue, :init}} 
  end

  @impl GenServer
  def handle_continue(:init, {list_name, nil}) do
    todo_list = Todo.Database.get(list_name) || Todo.List.new()
    {:noreply, {list_name, todo_list}}
  end

  @impl GenServer
  def handle_cast({:add_entry, new_entry}, {list_name, list}) do
    new_list = Todo.List.add_entry(list, new_entry)
    Todo.Database.store(list_name, new_list)
    {:noreply, {list_name, new_list}} 
  end

  @impl GenServer
  def handle_call({:entries, date}, _, {list_name, list}) do
    {:reply, Todo.List.entries(list, date), {list_name, list}}
  end
end

