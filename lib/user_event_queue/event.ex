defmodule UserEventQueue.Event do
  @derive {Jason.Encoder, except: [:message_id, :message_group_id, :receipt_handle, :source_id]}
  defstruct ~w(type message_id message_group_id data receipt_handle source_id)a
end
