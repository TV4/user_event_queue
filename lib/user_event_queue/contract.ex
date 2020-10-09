defmodule UserEventQueue.Contract do
  defstruct [:customer_id, :order_id, :added_item_id, :removed_item_id, :currency]

  @type t :: %__MODULE__{}
end
