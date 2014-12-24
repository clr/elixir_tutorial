defmodule MyApp.BucketTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, bucket} = MyApp.Bucket.start_link
    {:ok, bucket: bucket}
  end

  test "stores values by key", %{bucket: bucket} do
    assert MyApp.Bucket.get(bucket, "leaf") == nil

    MyApp.Bucket.put(bucket, "leaf", 10)
    assert MyApp.Bucket.get(bucket, "leaf") == 10
  end

  test "deletes values by key", %{bucket: bucket} do
    MyApp.Bucket.put(bucket, "leaf", 10)

    assert MyApp.Bucket.delete(bucket, "leaf") == 10
    assert MyApp.Bucket.get(bucket, "leaf") == nil
  end
end
