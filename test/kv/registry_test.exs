defmodule MyApp.RegistryTest do
  use ExUnit.Case, async: true

  defmodule Forwarder do
    use GenEvent

    def handle_event(event, parent) do
      send parent, event
      {:ok, parent}
    end
  end

  setup do
    {:ok, supervisor} = MyApp.Bucket.Supervisor.start_link
    {:ok, manager}    = GenEvent.start_link
    {:ok, registry}   = MyApp.Registry.start_link(:registry_table, manager, supervisor)

    GenEvent.add_mon_handler(manager, Forwarder, self())
    {:ok, registry: registry, ets: :registry_table}
  end

  test "sends event on crash and create", %{registry: registry, ets: ets} do
    MyApp.Registry.create(registry, "pizza")
    {:ok, bucket} = MyApp.Registry.lookup(ets, "pizza")
    assert_receive {:create, "pizza", bucket}

    Agent.stop(bucket)
    assert_receive {:stop, "pizza", bucket}
  end

  test "spawn buckets", %{registry: registry, ets: ets} do
    assert MyApp.Registry.lookup(ets, "shopping") == :error

    MyApp.Registry.create(registry, "shoppee")
    assert {:ok, bucket} = MyApp.Registry.lookup(ets, "shoppee")

    MyApp.Bucket.put(bucket, "leaf", 10)
    assert MyApp.Bucket.get(bucket, "leaf") == 10
  end

  test "removes registry entry on exit", %{registry: registry, ets: ets} do
    MyApp.Registry.create(registry, "shoppers")
    {:ok, bucket} = MyApp.Registry.lookup(ets, "shoppers")
    Agent.stop(bucket)
    assert_receive {:stop, "shoppers", bucket}
    assert MyApp.Registry.lookup(ets, "shoppers") == :error
  end

  test "removes bucket on crash", %{registry: registry, ets: ets} do
    MyApp.Registry.create(registry, "leaf")
    {:ok, bucket} = MyApp.Registry.lookup(ets, "leaf")

    Process.exit(bucket, :shutdown)
    assert_receive {:stop, "leaf", bucket}
    assert MyApp.Registry.lookup(ets, "leaf") == :error
  end
end
