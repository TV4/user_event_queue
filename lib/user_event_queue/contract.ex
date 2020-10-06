defmodule UserEventQueue.Contract do
  defstruct [:customer_id, :order_id]

  @type t :: %__MODULE__{}
end
