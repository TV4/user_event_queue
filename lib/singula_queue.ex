defmodule SingulaQueue do
  require Logger

  alias SingulaQueue.{AccountUser, AccountUserEvent}

  @callback attributes() :: map()
  def attributes() do
    message = ExAws.SQS.get_queue_attributes(queue_url())

    with {:ok, %{body: %{attributes: attributes}}} <- ExAws.request(message, config()) do
      attributes
    end
  end

  @callback dlq_attributes() :: map()
  def dlq_attributes do
    message = ExAws.SQS.get_queue_attributes(dlq_url())

    with {:ok, %{body: %{attributes: attributes}}} <- ExAws.request(message, config()) do
      attributes
    end
  end

  @callback enqueue(atom(), String.t(), AccountUser.t()) :: :ok
  def enqueue(event, group_by, account_user) do
    event = %AccountUserEvent{type: event, data: AccountUser.to_user_map(account_user)}

    message =
      ExAws.SQS.send_message(queue_url(), Jason.encode!(event), message_group_id: group_by)

    with {:ok, %{status_code: 200}} <- ExAws.request(message, config()) do
      Logger.info("count#singula_import_queue.enqueue.count=1")
      :ok
    end
  end

  @callback poll :: [%AccountUserEvent{data: %AccountUser{}}] | nil
  def poll() do
    message =
      ExAws.SQS.receive_message(
        queue_url(),
        max_number_of_messages: 10,
        attribute_names: [:message_group_id]
      )

    with {:ok, %{body: %{messages: sqs_messages}}} <- ExAws.request(message, config()) do
      message_count = length(sqs_messages)

      if message_count > 0 do
        Logger.info("count#singula_import_queue.poll.count=#{message_count}")
      end

      to_user_events(sqs_messages)
    else
      error -> IO.inspect(error, label: :poll_payload_error)
    end
  end

  defp to_user_events(messages) do
    messages
    |> Enum.map(fn %{
                     body: body,
                     receipt_handle: receipt_handle,
                     attributes: %{"message_group_id" => message_group_id}
                   } ->
      case Jason.decode(body) do
        {:ok, %{"type" => type, "data" => data}} ->
          %AccountUserEvent{
            type: String.to_atom(type),
            data: AccountUser.parse(data),
            receipt_handle: receipt_handle,
            message_group_id: message_group_id
          }

        _ ->
          :error
      end
    end)
    |> Enum.reject(fn message -> message == :error end)
  end

  @callback delete(String.t()) :: :ok
  def delete(receipt_handle) do
    message = ExAws.SQS.delete_message(queue_url(), receipt_handle)

    with {:ok, %{status_code: 200}} <- ExAws.request(message, config()) do
      Logger.info("count#singula_import_queue.delete.count=1")
      :ok
    end
  end

  defp queue_url, do: Application.get_env(:singula_queue, :singula_queue_url)

  defp dlq_url, do: Application.get_env(:singula_queue, :singula_dlq_url)

  defp config do
    [
      http_client: Application.get_env(:singula_queue, :http_client, HTTPoison),
      json_codec: Jason,
      access_key_id: Application.get_env(:singula_queue, :queue_access_key_id),
      secret_access_key: Application.get_env(:singula_queue, :queue_secret_access_key),
      region: Application.get_env(:singula_queue, :queue_region)
    ]
  end
end
