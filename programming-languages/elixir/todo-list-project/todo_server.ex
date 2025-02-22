defmodule TodoServer do
  def start do
    spawn(fn -> 
      Process.register(self(), :todo_server)
      loop(TodoList.new()) 
    end)
  end
  
  def add_entry(new_entry) do
    send(:todo_server, {:add_entry, new_entry})  
  end

  def entries(date) do
    send(:todo_server, {:entries, self(), date})  

    receive do
      {:todo_entries, entries} -> entries
    after
      5000 -> {:error, :timeout}
    end
  end

  defp loop(list) do
    new_list = 
      receive do
        message -> process_message(list, message)
      end

    loop(new_list)
  end

  defp process_message(list, {:add_entry, new_entry}), do: TodoList.add_entry(list, new_entry)  
  defp process_message(list, {:entries, caller, date}) do
    send(caller, {:todo_entries, TodoList.entries(list, date)})
    list
  end
  defp process_message(list, _), do: list
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

