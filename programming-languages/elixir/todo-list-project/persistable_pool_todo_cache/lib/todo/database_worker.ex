defmodule Todo.DatabaseWorker do
  use GenServer

  def start(db_folder) do
    GenServer.start(__MODULE__, db_folder)  
  end
   
  def store(pid, key, content) do
    GenServer.cast(pid, {:store, key, content})
  end

  def get(pid, key) do
    GenServer.call(pid, {:get, key}) 
  end

  @impl GenServer
  def init(db_folder) do
    {:ok, db_folder}  
  end

  @impl GenServer
  def handle_cast({:store, key, content}, db_folder) do
    db_folder
    |> file_name(key)
    |> File.write!(:erlang.binary_to_term(content))

    {:noreply, db_folder}
  end

  @impl GenServer
  def handle_call({:get, key}, _, db_folder) do
    data = 
      case File.read(file_name(db_folder, key)) do
        {:ok, content} -> :erlang.term_to_binary(content)
        _ -> nil
      end

    {:reply, data, db_folder}
  end

  def file_name(path, key) do
    Path.join(path, to_string(key))
  end
end
