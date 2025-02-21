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

defmodule TodoList.CSVImporter do
  def import(file) do
    File.stream!(file)
    |> Stream.map(&String.split(&1, "\n", trim: true))
    |> Stream.map(&String.split(Enum.at(&1, 0), ", "))
    |> Stream.map(&([Date.from_iso8601!(Enum.at(&1, 0)), Enum.at(&1, 1)]))
    |> Enum.reduce([], fn [date, task], acc -> [%{date: date, task: task} | acc] end)
    |> Enum.reverse()
    |> TodoList.new()
  end  
end

defimpl String.Chars, for: TodoList do
  def to_string(_) do
    "#TodoList" 
  end
end

defimpl Collectable, for: TodoList do
  def into(original) do
    {original, &into_callback/2}
  end

  defp into_callback(list, {:cont, entry}) do
    TodoList.add_entry(list, entry) 
  end

  defp into_callback(list, :done), do: list
  defp into_callback(_list, :halt), do: :ok
end

# expect #TodoList
IO.puts(TodoList.new())

#
entries = [
  %{date: ~D[2023-12-19], task: "Dentist"},
  %{date: ~D[2023-12-20], task: "Shopping"},
  %{date: ~D[2023-12-19], task: "Movies"}
]

# expect to print out a list with all 3 task above in that same order
Enum.into(entries, TodoList.new())
|> IO.inspect()
