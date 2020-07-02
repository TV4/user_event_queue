ExUnit.configure(exclude: :pending, timeout: 10000)
# ExUnit.configure(include: :wip, exclude: :test)
Application.put_all_env(
  user_event_queue: [
    http_client: MockHTTPClient,
    access_key_id: "key",
    secret_access_key: "secret",
    region: "eu-central-1",
    queue_url: "https://sqs.eu-central-1.amazonaws.com/123456789012/PaywizardQueue.fifo",
    dlq_url: "https://sqs.eu-central-1.amazonaws.com/123456789012/PaywizardDLQ.fifo"
  ]
)

ExUnit.start()
