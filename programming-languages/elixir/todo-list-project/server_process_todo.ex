defmodule ServerProcess do
  def start(callback_module) do
    spawn(fn ->
      initial_state = callback_module.init()
      loop(callback_module, initial_state)
    end)
  end
  
  def call(server_pid, request) do
    send(server_pid, {request, self()})  

    receive do
      {:response, response} -> response
    end
  end

  defp loop(callback_module, current_state) do
    receive do
      {request, caller} ->
        {response, new_state} = callback_module.handle_call(request, current_state)
        send(caller, {:response, response})

        loop(callback_module, new_state)
    end
  end
end

defmodule TodoServer do
  def start do
    ServerProcess.start(TodoServer)
  end
  
  def init do
    TodoList.new()
  end

  def add_entry(pid, new_entry) do
    ServerProcess.call(pid, {:add_entry, new_entry})  
  end

  def entries(pid, date) do
    ServerProcess.call(pid, {:entries, self(), date})  

    receive do
      {:todo_entries, entries} -> entries
    after
      5000 -> {:error, :timeout}
    end
  end

  def handle_call({:add_entry, new_entry}, list), do: {:ok, TodoList.add_entry(list, new_entry)}
  def handle_call({:entries, caller, date}, list) do
    send(caller, {:todo_entries, TodoList.entries(list, date)})
    {:ok, list}
  end
  def handle_call(_), do: {:error, :invalid_call}
end

defmodule TodoList do
  defstruct next_id: 1, entries: %{} 

  def new(entries \\ []) do
    Enum.reduce(entries, %TodoList{}, &(add_entry(&2, &1)))
  end

  def add_entry(list, entry) do
    new_entry = Map.put(entry, :id, list.next_id)
    new_entries = Map.put(list.entries, list.next_id, new_entry) 

    %TodoList{list | 
      next_id: list.next_id + 1,
      entries: new_entries
    }
  end

  def update_entry(list, entry_id, updater_fn) do
    case Map.fetch(list.entries, entry_id) do
      :error -> 
        list

      {:ok, old_entry} ->
        new_entry = updater_fn.(old_entry)
        new_entries = Map.put(list.entries, new_entry.id, new_entry)
        %TodoList{list | entries: new_entries}
    end
  end

  def delete_entry(list, entry_id) do
    case Map.fetch(list.entries, entry_id) do
      :error ->
        list

      {:ok, _} ->
        new_entries = Map.delete(list.entries, entry_id)  
        %TodoList{list | entries: new_entries}
    end 
  end

  def entries(list, date) do
    list.entries
    |> Map.values()
    |> Enum.filter(&(&1.date == date))
  end
end

