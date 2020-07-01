defmodule SingulaQueue.AccountUserEvent do
  @derive {Jason.Encoder, except: [:message_group_id, :receipt_handle, :source_id]}
  defstruct ~w(type message_group_id data receipt_handle source_id)a
end
