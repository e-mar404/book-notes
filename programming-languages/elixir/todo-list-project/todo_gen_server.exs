defmodule TodoServer do
  use GenServer

  def start do
    GenServer.start(__MODULE__, nil, name: __MODULE__)
  end
  
  def init(_) do
    {:ok, TodoList.new()}
  end

  def add_entry(new_entry) do
    GenServer.cast(__MODULE__, {:add_entry, new_entry})  
  end

  def entries(date) do
    GenServer.call(__MODULE__, {:entries, date})  
  end

  def handle_cast({:add_entry, new_entry}, list) do
    {:noreply, TodoList.add_entry(list, new_entry)}
  end

  def handle_call({:entries, date}, _, list) do
    {:reply, TodoList.entries(list, date), list}
  end
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

TodoServer.start()
TodoServer.add_entry(%{date: ~D[2023-12-19], task: "dentis"})
TodoServer.add_entry(%{date: ~D[2023-12-19], task: "movies"})
IO.inspect TodoServer.entries(~D[2023-12-19])
