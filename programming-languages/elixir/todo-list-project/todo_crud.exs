defmodule TodoList do
  defstruct next_id: 1, entries: %{} 

  def new(), do: %TodoList{} 

  def add_entry(list, entry) do
    new_entry = Map.put(entry, :id, list.next_id)
    new_entries = Map.put(list.entries, list.next_id, new_entry) 

    %TodoList{list | 
      entries: new_entries,
      next_id: list.next_id + 1
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

IO.puts "creating list..."
list = TodoList.new()
|> TodoList.add_entry(%{date: ~D[2023-12-19], task: "Dentist"})
|> TodoList.add_entry(%{date: ~D[2023-12-20], task: "Shopping"})
|> TodoList.add_entry(%{date: ~D[2023-12-19], task: "Movies"})

# expect [%{id: 1, date: ~D[2023-12-19], task: "Movies"}, %{id: 3, date: ~D[2023-12-19], task: "Dentist"}]
IO.puts "getting entries for day 2023-12-19"
list
|> TodoList.entries(~D[2023-12-19])
|> IO.inspect()

# expect [%{id: 2, date: ~D[2023-12-20], task: "Dinner"]} 
IO.puts "updating entry with id 2"
list
|> TodoList.update_entry(2, &(Map.put(&1, :task, "Dinner")))
|> TodoList.entries(~D[2023-12-20])
|> IO.inspect()

# expect [%{id: 3, date: ~D[2023-12-19], task: "Dentist"}]
IO.puts "deleting entry with id 1"
list
|> TodoList.delete_entry(1)
|> TodoList.entries(~D[2023-12-19])
|> IO.inspect()
