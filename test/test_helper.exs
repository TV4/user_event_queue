ExUnit.configure(exclude: :pending, timeout: 10000)
# ExUnit.configure(include: :wip, exclude: :test)
Application.put_all_env(
  singula_queue: [
    http_client: MockHTTPClient,
    queue_access_key_id: "key",
    queue_secret_access_key: "secret",
    queue_region: "eu-central-1",
    singula_queue_url: "https://sqs.eu-central-1.amazonaws.com/123456789012/PaywizardQueue.fifo",
    singula_dlq_url: "https://sqs.eu-central-1.amazonaws.com/123456789012/PaywizardDLQ.fifo"
  ]
)

ExUnit.start()
