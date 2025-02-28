defmodule Todo.Database do
  use GenServer

  @db_folder "./persist"

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def store(key, data) do
    worker = GenServer.call(__MODULE__, {:choose_worker, key})
    Todo.DatabaseWorker.store(worker, key, data)
  end

  def get(key) do
    worker = GenServer.call(__MODULE__, {:choose_worker, key})
    Todo.DatabaseWorker.get(worker, key)
  end

  @impl GenServer
  def init(_) do
    IO.puts "Starting to-do database"
    {:ok, nil, {:continue, :init}}
  end

  @impl GenServer
  def handle_continue(:init, _) do
    File.mkdir_p!(@db_folder)

    workers = Enum.map(1..3, fn _ -> 
      {:ok, pid} = Todo.DatabaseWorker.start_link(@db_folder) 
      pid
    end)

    {:noreply, workers}
  end

  @impl GenServer
  def handle_call({:choose_worker, key}, _, workers) do
    idx = Integer.mod(:erlang.phash2(key), 3)
    worker = Enum.at(workers, idx)
    {:reply, worker, workers}
  end
end
