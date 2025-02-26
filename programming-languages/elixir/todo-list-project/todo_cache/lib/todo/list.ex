defmodule Todo.List do
  defstruct next_id: 1, entries: %{} 

  def new(entries \\ []) do
    Enum.reduce(entries, %Todo.List{}, &(add_entry(&2, &1)))
  end

  def add_entry(list, entry) do
    new_entry = Map.put(entry, :id, list.next_id)
    new_entries = Map.put(list.entries, list.next_id, new_entry) 

    %Todo.List{list | 
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
        %Todo.List{list | entries: new_entries}
    end
  end

  def delete_entry(list, entry_id) do
    case Map.fetch(list.entries, entry_id) do
      :error ->
        list

      {:ok, _} ->
        new_entries = Map.delete(list.entries, entry_id)  
        %Todo.List{list | entries: new_entries}
    end 
  end

  def entries(list, date) do
    list.entries
    |> Map.values()
    |> Enum.filter(&(&1.date == date))
  end
end
