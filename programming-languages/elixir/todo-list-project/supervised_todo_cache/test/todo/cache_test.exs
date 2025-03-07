defmodule Todo.CacheTest do
  use ExUnit.Case

  test "server_process" do
    {:ok, cache} = Todo.Cache.start_link()
    bob_pid = Todo.Cache.server_process(cache, "bob")

    assert bob_pid != Todo.Cache.server_process(cache, "alice")
    assert bob_pid == Todo.Cache.server_process(cache, "bob")
  end  

  test "to-do operations" do
    {:ok, cache} = Todo.Cache.start_link()
    alice = Todo.Cache.server_process(cache, "alice") 
    Todo.Server.add_entry(
      alice,
      %{date: ~D[2023-12-19], task: "Dentist"}
    )

    entries = Todo.Server.entries(alice, ~D[2023-12-19])
    assert [%{date: ~D[2023-12-19], task: "Dentist"}] = entries 
  end
end
