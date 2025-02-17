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

  def entries(list, date) do
    list.entries
    |> Map.values()
    |> Enum.filter(&(&1.date == date))
  end
end

# expect [%{id: 1, date: ~D[2023-12-19], task: "Movies"}, %{id: 3, date: ~D[2023-12-19], task: "Dentist"}]
TodoList.new()
|> TodoList.add_entry(%{date: ~D[2023-12-19], task: "Dentist"})
|> TodoList.add_entry(%{date: ~D[2023-12-20], task: "Shopping"})
|> TodoList.add_entry(%{date: ~D[2023-12-19], task: "Movies"})
|> TodoList.entries(~D[2023-12-19])
|> IO.inspect()
