defmodule SingulaQueueTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  import Mox

  alias SingulaQueue.{AccountUser, AccountUserEvent}

  setup :verify_on_exit!

  @account_user %AccountUser{
    user_id: "123",
    username: "username",
    email: "user@host.com",
    first_name: "user",
    last_name: "test",
    zip_code: "12345",
    country_code: "SWE",
    year_of_birth: 1990,
    accepted_cmore_terms: "2018-08-08",
    accepted_play_terms: "2019-10-16",
    accepted_fotbollskanalen_terms: "2012-12-12",
    generic_ads: false,
    no_ads: false,
    cmore_newsletter: false
  }

  setup do
    level = Logger.level()
    Logger.configure(level: :info)
    on_exit(fn -> Logger.configure(level: level) end)
  end

  test "enqueue create user message" do
    MockHTTPClient
    |> expect(:request, fn :post,
                           "https://sqs.eu-central-1.amazonaws.com/",
                           body,
                           _headers,
                           _http_opts ->
      assert URI.decode_query(body) == %{
               "Action" => "SendMessage",
               "MessageBody" => Jason.encode!(%{type: "create", data: @account_user}),
               "MessageGroupId" => "123",
               "QueueUrl" =>
                 "https://sqs.eu-central-1.amazonaws.com/123456789012/PaywizardQueue.fifo"
             }

      {:ok,
       %{
         body:
           "<?xml version=\"1.0\"?><SendMessageResponse xmlns=\"http://queue.amazonaws.com/doc/2012-11-05/\"><SendMessageResult><MessageId>4e5dcf44-8e1b-4e4d-adaa-bd374c6f25f6</MessageId><MD5OfMessageBody>a964c040bf2d4dfafac3513c63fead5f</MD5OfMessageBody><SequenceNumber>18849261735625455872</SequenceNumber></SendMessageResult><ResponseMetadata><RequestId>3aec5d1a-3ece-572f-8fd3-0b2bd096891e</RequestId></ResponseMetadata></SendMessageResponse>",
         headers: [
           {"x-amzn-RequestId", "3aec5d1a-3ece-572f-8fd3-0b2bd096891e"},
           {"Date", "Tue, 29 Oct 2019 07:36:56 GMT"},
           {"Content-Type", "text/xml"},
           {"Content-Length", "431"}
         ],
         status_code: 200
       }}
    end)

    assert capture_log(fn ->
             assert SingulaQueue.enqueue(:create, "123", @account_user) == :ok
           end) =~ "count#singula_import_queue.enqueue.count=1"
  end

  test "enqueue update user message" do
    MockHTTPClient
    |> expect(:request, fn :post,
                           "https://sqs.eu-central-1.amazonaws.com/",
                           body,
                           _headers,
                           _http_opts ->
      assert URI.decode_query(body) == %{
               "Action" => "SendMessage",
               "MessageBody" => Jason.encode!(%{type: "update", data: @account_user}),
               "MessageGroupId" => "123",
               "QueueUrl" =>
                 "https://sqs.eu-central-1.amazonaws.com/123456789012/PaywizardQueue.fifo"
             }

      {:ok,
       %{
         body:
           "<?xml version=\"1.0\"?><SendMessageResponse xmlns=\"http://queue.amazonaws.com/doc/2012-11-05/\"><SendMessageResult><MessageId>4e5dcf44-8e1b-4e4d-adaa-bd374c6f25f6</MessageId><MD5OfMessageBody>a964c040bf2d4dfafac3513c63fead5f</MD5OfMessageBody><SequenceNumber>18849261735625455872</SequenceNumber></SendMessageResult><ResponseMetadata><RequestId>3aec5d1a-3ece-572f-8fd3-0b2bd096891e</RequestId></ResponseMetadata></SendMessageResponse>",
         headers: [
           {"x-amzn-RequestId", "3aec5d1a-3ece-572f-8fd3-0b2bd096891e"},
           {"Date", "Tue, 29 Oct 2019 07:36:56 GMT"},
           {"Content-Type", "text/xml"},
           {"Content-Length", "431"}
         ],
         status_code: 200
       }}
    end)

    assert capture_log(fn ->
             assert SingulaQueue.enqueue(:update, "123", @account_user) == :ok
           end) =~ "count#singula_import_queue.enqueue.count=1"
  end

  test "enqueue delete user message" do
    MockHTTPClient
    |> expect(:request, fn :post,
                           "https://sqs.eu-central-1.amazonaws.com/",
                           body,
                           _headers,
                           _http_opts ->
      assert URI.decode_query(body) == %{
               "Action" => "SendMessage",
               "MessageBody" => Jason.encode!(%{type: "delete", data: %{user_id: "123"}}),
               "MessageGroupId" => "123",
               "QueueUrl" =>
                 "https://sqs.eu-central-1.amazonaws.com/123456789012/PaywizardQueue.fifo"
             }

      {:ok,
       %{
         body:
           "<?xml version=\"1.0\"?><SendMessageResponse xmlns=\"http://queue.amazonaws.com/doc/2012-11-05/\"><SendMessageResult><MessageId>4e5dcf44-8e1b-4e4d-adaa-bd374c6f25f6</MessageId><MD5OfMessageBody>a964c040bf2d4dfafac3513c63fead5f</MD5OfMessageBody><SequenceNumber>18849261735625455872</SequenceNumber></SendMessageResult><ResponseMetadata><RequestId>3aec5d1a-3ece-572f-8fd3-0b2bd096891e</RequestId></ResponseMetadata></SendMessageResponse>",
         headers: [
           {"x-amzn-RequestId", "3aec5d1a-3ece-572f-8fd3-0b2bd096891e"},
           {"Date", "Tue, 29 Oct 2019 07:36:56 GMT"},
           {"Content-Type", "text/xml"},
           {"Content-Length", "431"}
         ],
         status_code: 200
       }}
    end)

    assert capture_log(fn ->
             assert SingulaQueue.enqueue(:delete, "123", %AccountUser{user_id: "123"}) == :ok
           end) =~ "count#singula_import_queue.enqueue.count=1"
  end

  describe "poll" do
    test "with an empty queue" do
      MockHTTPClient
      |> expect(:request, fn :post,
                             "https://sqs.eu-central-1.amazonaws.com/",
                             body,
                             _headers,
                             _http_opts ->
        assert URI.decode_query(body) == %{
                 "QueueUrl" =>
                   "https://sqs.eu-central-1.amazonaws.com/123456789012/PaywizardQueue.fifo",
                 "Action" => "ReceiveMessage",
                 "MaxNumberOfMessages" => "10",
                 "AttributeName.1" => "MessageGroupId"
               }

        {:ok,
         %{
           body:
             "<?xml version=\"1.0\"?><ReceiveMessageResponse xmlns=\"http://queue.amazonaws.com/doc/2012-11-05/\"><ReceiveMessageResult/><ResponseMetadata><RequestId>4cc69ec3-bcf9-5649-9031-c8f1aae78878</RequestId></ResponseMetadata></ReceiveMessageResponse>",
           headers: [
             {"x-amzn-RequestId", "4cc69ec3-bcf9-5649-9031-c8f1aae78878"},
             {"Date", "Tue, 29 Oct 2019 10:26:38 GMT"},
             {"Content-Type", "text/xml"},
             {"Content-Length", "240"}
           ],
           status_code: 200
         }}
      end)

      assert SingulaQueue.poll() == []
    end

    test "with a create message" do
      MockHTTPClient
      |> expect(:request, fn :post,
                             "https://sqs.eu-central-1.amazonaws.com/",
                             body,
                             _headers,
                             _http_opts ->
        assert URI.decode_query(body) == %{
                 "QueueUrl" =>
                   "https://sqs.eu-central-1.amazonaws.com/123456789012/PaywizardQueue.fifo",
                 "Action" => "ReceiveMessage",
                 "MaxNumberOfMessages" => "10",
                 "AttributeName.1" => "MessageGroupId"
               }

        {:ok,
         %{
           body:
             "<?xml version=\"1.0\"?><ReceiveMessageResponse xmlns=\"http://queue.amazonaws.com/doc/2012-11-05/\"><ReceiveMessageResult><Message><MessageId>32542295-1642-40b8-a7ff-f448b20b096a</MessageId><ReceiptHandle>AQEBdj8hI0xLQzPUAz8gIbJm7yj/jZPU0A84EaWKq9xekGvW+JwCYVOgfJnJNU9iKPEIecLyrlkzC10g7bZQp64ybmuRkPMF2BEpBwz8wUm/oKUCnQFNddEGFg+B/+ZY1yrEGQm5ADHT16uOESh4kQ+2NJH5qTGWj+zrC30KrtAfI0PDXWJ43AVntuX2KorKk7TOYU7Lz5Nw8HkDQVx8ClXveMy7p0xM13274lLjkQcGJam+ztbsQhh6cMAdriqklt1EIowkQAYroHWhKWVJOhxsBm5PG8IvEPIhQ0TuEaLYQ08=</ReceiptHandle><MD5OfBody>8f07143838000dec8feba6987e855741</MD5OfBody><Body>{&quot;data&quot;:{&quot;accepted_cmore_terms&quot;:&quot;2018-08-08&quot;,&quot;accepted_fotbollskanalen_terms&quot;:&quot;2012-12-12&quot;,&quot;accepted_play_terms&quot;:&quot;2019-10-16&quot;,&quot;cmore_newsletter&quot;:false,&quot;country_code&quot;:&quot;SWE&quot;,&quot;email&quot;:&quot;user@host.com&quot;,&quot;first_name&quot;:&quot;user&quot;,&quot;generic_ads&quot;:false,&quot;last_name&quot;:&quot;test&quot;,&quot;no_ads&quot;:false,&quot;user_id&quot;:&quot;1234&quot;,&quot;username&quot;:&quot;username&quot;,&quot;year_of_birth&quot;:1990,&quot;zip_code&quot;:&quot;12345&quot;},&quot;type&quot;:&quot;create&quot;}</Body><Attribute><Name>MessageGroupId</Name><Value>1234</Value></Attribute></Message></ReceiveMessageResult><ResponseMetadata><RequestId>b562c8fd-7224-5264-a90b-9ecf60d70837</RequestId></ResponseMetadata></ReceiveMessageResponse>",
           headers: [
             {"x-amzn-RequestId", "b562c8fd-7224-5264-a90b-9ecf60d70837"},
             {"Date", "Tue, 29 Oct 2019 10:13:07 GMT"},
             {"Content-Type", "text/xml"},
             {"Content-Length", "1324"}
           ],
           status_code: 200
         }}
      end)

      assert capture_log(fn ->
               assert SingulaQueue.poll() == [
                        %AccountUserEvent{
                          type: :create,
                          message_group_id: 1234,
                          data: %AccountUser{
                            accepted_cmore_terms: "2018-08-08",
                            accepted_fotbollskanalen_terms: "2012-12-12",
                            accepted_play_terms: "2019-10-16",
                            cmore_newsletter: false,
                            country_code: "SWE",
                            email: "user@host.com",
                            first_name: "user",
                            generic_ads: false,
                            last_name: "test",
                            no_ads: false,
                            user_id: "1234",
                            username: "username",
                            year_of_birth: 1990,
                            zip_code: "12345"
                          },
                          receipt_handle:
                            "AQEBdj8hI0xLQzPUAz8gIbJm7yj/jZPU0A84EaWKq9xekGvW+JwCYVOgfJnJNU9iKPEIecLyrlkzC10g7bZQp64ybmuRkPMF2BEpBwz8wUm/oKUCnQFNddEGFg+B/+ZY1yrEGQm5ADHT16uOESh4kQ+2NJH5qTGWj+zrC30KrtAfI0PDXWJ43AVntuX2KorKk7TOYU7Lz5Nw8HkDQVx8ClXveMy7p0xM13274lLjkQcGJam+ztbsQhh6cMAdriqklt1EIowkQAYroHWhKWVJOhxsBm5PG8IvEPIhQ0TuEaLYQ08="
                        }
                      ]
             end) =~ "count#singula_import_queue.poll.count=1"
    end

    test "with an update message" do
      MockHTTPClient
      |> expect(:request, fn :post,
                             "https://sqs.eu-central-1.amazonaws.com/",
                             body,
                             _headers,
                             _http_opts ->
        assert URI.decode_query(body) == %{
                 "QueueUrl" =>
                   "https://sqs.eu-central-1.amazonaws.com/123456789012/PaywizardQueue.fifo",
                 "Action" => "ReceiveMessage",
                 "MaxNumberOfMessages" => "10",
                 "AttributeName.1" => "MessageGroupId"
               }

        {:ok,
         %{
           body:
             "<?xml version=\"1.0\"?><ReceiveMessageResponse xmlns=\"http://queue.amazonaws.com/doc/2012-11-05/\"><ReceiveMessageResult><Message><MessageId>32542295-1642-40b8-a7ff-f448b20b096a</MessageId><ReceiptHandle>AQEBdj8hI0xLQzPUAz8gIbJm7yj/jZPU0A84EaWKq9xekGvW+JwCYVOgfJnJNU9iKPEIecLyrlkzC10g7bZQp64ybmuRkPMF2BEpBwz8wUm/oKUCnQFNddEGFg+B/+ZY1yrEGQm5ADHT16uOESh4kQ+2NJH5qTGWj+zrC30KrtAfI0PDXWJ43AVntuX2KorKk7TOYU7Lz5Nw8HkDQVx8ClXveMy7p0xM13274lLjkQcGJam+ztbsQhh6cMAdriqklt1EIowkQAYroHWhKWVJOhxsBm5PG8IvEPIhQ0TuEaLYQ08=</ReceiptHandle><MD5OfBody>8f07143838000dec8feba6987e855741</MD5OfBody><Body>{&quot;data&quot;:{&quot;email&quot;:&quot;user@host.com&quot;,&quot;user_id&quot;:&quot;1234&quot;,&quot;username&quot;:&quot;username&quot;},&quot;type&quot;:&quot;update&quot;}</Body><Attribute><Name>MessageGroupId</Name><Value>1234</Value></Attribute></Message></ReceiveMessageResult><ResponseMetadata><RequestId>b562c8fd-7224-5264-a90b-9ecf60d70837</RequestId></ResponseMetadata></ReceiveMessageResponse>",
           headers: [
             {"x-amzn-RequestId", "b562c8fd-7224-5264-a90b-9ecf60d70837"},
             {"Date", "Tue, 29 Oct 2019 10:13:07 GMT"},
             {"Content-Type", "text/xml"},
             {"Content-Length", "1324"}
           ],
           status_code: 200
         }}
      end)

      assert capture_log(fn ->
               assert SingulaQueue.poll() == [
                        %AccountUserEvent{
                          type: :update,
                          message_group_id: 1234,
                          data: %AccountUser{
                            user_id: "1234",
                            username: "username",
                            email: "user@host.com"
                          },
                          receipt_handle:
                            "AQEBdj8hI0xLQzPUAz8gIbJm7yj/jZPU0A84EaWKq9xekGvW+JwCYVOgfJnJNU9iKPEIecLyrlkzC10g7bZQp64ybmuRkPMF2BEpBwz8wUm/oKUCnQFNddEGFg+B/+ZY1yrEGQm5ADHT16uOESh4kQ+2NJH5qTGWj+zrC30KrtAfI0PDXWJ43AVntuX2KorKk7TOYU7Lz5Nw8HkDQVx8ClXveMy7p0xM13274lLjkQcGJam+ztbsQhh6cMAdriqklt1EIowkQAYroHWhKWVJOhxsBm5PG8IvEPIhQ0TuEaLYQ08="
                        }
                      ]
             end) =~ "count#singula_import_queue.poll.count=1"
    end

    test "with a delete message" do
      MockHTTPClient
      |> expect(:request, fn :post,
                             "https://sqs.eu-central-1.amazonaws.com/",
                             body,
                             _headers,
                             _http_opts ->
        assert URI.decode_query(body) == %{
                 "QueueUrl" =>
                   "https://sqs.eu-central-1.amazonaws.com/123456789012/PaywizardQueue.fifo",
                 "Action" => "ReceiveMessage",
                 "MaxNumberOfMessages" => "10",
                 "AttributeName.1" => "MessageGroupId"
               }

        {:ok,
         %{
           body:
             "<?xml version=\"1.0\"?><ReceiveMessageResponse xmlns=\"http://queue.amazonaws.com/doc/2012-11-05/\"><ReceiveMessageResult><Message><MessageId>32542295-1642-40b8-a7ff-f448b20b096a</MessageId><ReceiptHandle>AQEBdj8hI0xLQzPUAz8gIbJm7yj/jZPU0A84EaWKq9xekGvW+JwCYVOgfJnJNU9iKPEIecLyrlkzC10g7bZQp64ybmuRkPMF2BEpBwz8wUm/oKUCnQFNddEGFg+B/+ZY1yrEGQm5ADHT16uOESh4kQ+2NJH5qTGWj+zrC30KrtAfI0PDXWJ43AVntuX2KorKk7TOYU7Lz5Nw8HkDQVx8ClXveMy7p0xM13274lLjkQcGJam+ztbsQhh6cMAdriqklt1EIowkQAYroHWhKWVJOhxsBm5PG8IvEPIhQ0TuEaLYQ08=</ReceiptHandle><MD5OfBody>8f07143838000dec8feba6987e855741</MD5OfBody><Body>{&quot;data&quot;:{&quot;user_id&quot;:&quot;1234&quot;},&quot;type&quot;:&quot;delete&quot;}</Body><Attribute><Name>MessageGroupId</Name><Value>1234</Value></Attribute></Message></ReceiveMessageResult><ResponseMetadata><RequestId>b562c8fd-7224-5264-a90b-9ecf60d70837</RequestId></ResponseMetadata></ReceiveMessageResponse>",
           headers: [
             {"x-amzn-RequestId", "b562c8fd-7224-5264-a90b-9ecf60d70837"},
             {"Date", "Tue, 29 Oct 2019 10:13:07 GMT"},
             {"Content-Type", "text/xml"},
             {"Content-Length", "1324"}
           ],
           status_code: 200
         }}
      end)

      assert capture_log(fn ->
               assert SingulaQueue.poll() == [
                        %AccountUserEvent{
                          type: :delete,
                          message_group_id: 1234,
                          data: %AccountUser{user_id: "1234"},
                          receipt_handle:
                            "AQEBdj8hI0xLQzPUAz8gIbJm7yj/jZPU0A84EaWKq9xekGvW+JwCYVOgfJnJNU9iKPEIecLyrlkzC10g7bZQp64ybmuRkPMF2BEpBwz8wUm/oKUCnQFNddEGFg+B/+ZY1yrEGQm5ADHT16uOESh4kQ+2NJH5qTGWj+zrC30KrtAfI0PDXWJ43AVntuX2KorKk7TOYU7Lz5Nw8HkDQVx8ClXveMy7p0xM13274lLjkQcGJam+ztbsQhh6cMAdriqklt1EIowkQAYroHWhKWVJOhxsBm5PG8IvEPIhQ0TuEaLYQ08="
                        }
                      ]
             end) =~ "count#singula_import_queue.poll.count=1"
    end

    test "with a valid and an invalid message" do
      MockHTTPClient
      |> expect(:request, fn :post,
                             "https://sqs.eu-central-1.amazonaws.com/",
                             body,
                             _headers,
                             _http_opts ->
        assert URI.decode_query(body) == %{
                 "QueueUrl" =>
                   "https://sqs.eu-central-1.amazonaws.com/123456789012/PaywizardQueue.fifo",
                 "Action" => "ReceiveMessage",
                 "MaxNumberOfMessages" => "10",
                 "AttributeName.1" => "MessageGroupId"
               }

        {:ok,
         %{
           body:
             "<?xml version=\"1.0\"?><ReceiveMessageResponse xmlns=\"http://queue.amazonaws.com/doc/2012-11-05/\"><ReceiveMessageResult><Message><MessageId>32542295-1642-40b8-a7ff-f448b20b096a</MessageId><ReceiptHandle>AQEBdj8hI0xLQzPUAz8gIbJm7yj/jZPU0A84EaWKq9xekGvW+JwCYVOgfJnJNU9iKPEIecLyrlkzC10g7bZQp64ybmuRkPMF2BEpBwz8wUm/oKUCnQFNddEGFg+B/+ZY1yrEGQm5ADHT16uOESh4kQ+2NJH5qTGWj+zrC30KrtAfI0PDXWJ43AVntuX2KorKk7TOYU7Lz5Nw8HkDQVx8ClXveMy7p0xM13274lLjkQcGJam+ztbsQhh6cMAdriqklt1EIowkQAYroHWhKWVJOhxsBm5PG8IvEPIhQ0TuEaLYQ08=</ReceiptHandle><MD5OfBody>8f07143838000dec8feba6987e855741</MD5OfBody><Body>{&quot;data&quot;:{&quot;user_id&quot;:&quot;1234&quot;},&quot;type&quot;:&quot;delete&quot;}</Body><Attribute><Name>MessageGroupId</Name><Value>1234</Value></Attribute></Message><Message><MessageId>84fce719-8ca9-4cdc-8d40-46d338bae32b</MessageId><ReceiptHandle>AQEBh5q57ZK80hSy70sQPdZhfM1RQypfmG6rI8bcqKP0/Kgaxt6y5PBkCrCMJP1MHtQLmCKUi4uwTIdgvgeOqsimUO5A6TdzSKdBoPxxg0wV1+uU2zACDpWzXB93AO/AUtCYXFL3vQwmp1kedplnSrC0mDLu299mey6V5Uz02pAmtZCigM46tB2oBTWxxbbZM96vdfqK+/H9ZH0KqLJvvfCgZUH+C/7pbfk9ru4+e7e9C16AudEiWbGh53MMmy6IgofQ6OlpLvNEULhzcqlsLG/bZAxdwyDQUUPzWgNyT71AjF7twIKjRluSj3ZdhDkBLhMNKufvCwFAKV+DgV6BvKUlPw==</ReceiptHandle><MD5OfBody>54ddc3c7d064822eed932015d8740336</MD5OfBody><Body>broken</Body><Attribute><Name>MessageGroupId</Name><Value>1337</Value></Attribute></Message></ReceiveMessageResult><ResponseMetadata><RequestId>b562c8fd-7224-5264-a90b-9ecf60d70837</RequestId></ResponseMetadata></ReceiveMessageResponse>",
           headers: [
             {"x-amzn-RequestId", "b562c8fd-7224-5264-a90b-9ecf60d70837"},
             {"Date", "Tue, 29 Oct 2019 10:13:07 GMT"},
             {"Content-Type", "text/xml"},
             {"Content-Length", "1324"}
           ],
           status_code: 200
         }}
      end)

      assert capture_log(fn ->
               assert SingulaQueue.poll()
                      |> Enum.count() == 1
             end) =~ "count#singula_import_queue.poll.count=2"
    end
  end

  test "delete message from queue" do
    MockHTTPClient
    |> expect(:request, fn :post,
                           "https://sqs.eu-central-1.amazonaws.com/",
                           body,
                           _headers,
                           _http_opts ->
      assert URI.decode_query(body) == %{
               "QueueUrl" =>
                 "https://sqs.eu-central-1.amazonaws.com/123456789012/PaywizardQueue.fifo",
               "Action" => "DeleteMessage",
               "ReceiptHandle" =>
                 "AQEBdj8hI0xLQzPUAz8gIbJm7yj/jZPU0A84EaWKq9xekGvW+JwCYVOgfJnJNU9iKPEIecLyrlkzC10g7bZQp64ybmuRkPMF2BEpBwz8wUm/oKUCnQFNddEGFg+B/+ZY1yrEGQm5ADHT16uOESh4kQ+2NJH5qTGWj+zrC30KrtAfI0PDXWJ43AVntuX2KorKk7TOYU7Lz5Nw8HkDQVx8ClXveMy7p0xM13274lLjkQcGJam+ztbsQhh6cMAdriqklt1EIowkQAYroHWhKWVJOhxsBm5PG8IvEPIhQ0TuEaLYQ08="
             }

      {:ok,
       %{
         body:
           "<?xml version=\"1.0\"?><DeleteMessageResponse xmlns=\"http://queue.amazonaws.com/doc/2012-11-05/\"><ResponseMetadata><RequestId>00dd5e01-2e1f-554d-81c2-08330bf2ecd8</RequestId></ResponseMetadata></DeleteMessageResponse>",
         headers: [
           {"x-amzn-RequestId", "00dd5e01-2e1f-554d-81c2-08330bf2ecd8"},
           {"Date", "Tue, 29 Oct 2019 11:34:05 GMT"},
           {"Content-Type", "text/xml"},
           {"Content-Length", "215"}
         ],
         status_code: 200
       }}
    end)

    assert capture_log(fn ->
             assert SingulaQueue.delete(
                      "AQEBdj8hI0xLQzPUAz8gIbJm7yj/jZPU0A84EaWKq9xekGvW+JwCYVOgfJnJNU9iKPEIecLyrlkzC10g7bZQp64ybmuRkPMF2BEpBwz8wUm/oKUCnQFNddEGFg+B/+ZY1yrEGQm5ADHT16uOESh4kQ+2NJH5qTGWj+zrC30KrtAfI0PDXWJ43AVntuX2KorKk7TOYU7Lz5Nw8HkDQVx8ClXveMy7p0xM13274lLjkQcGJam+ztbsQhh6cMAdriqklt1EIowkQAYroHWhKWVJOhxsBm5PG8IvEPIhQ0TuEaLYQ08="
                    ) == :ok
           end) =~ "count#singula_import_queue.delete.count=1"
  end

  test "get queue attributes" do
    MockHTTPClient
    |> expect(:request, fn :post,
                           "https://sqs.eu-central-1.amazonaws.com/",
                           body,
                           _headers,
                           _http_opts ->
      assert URI.decode_query(body) == %{
               "QueueUrl" =>
                 "https://sqs.eu-central-1.amazonaws.com/123456789012/PaywizardQueue.fifo",
               "Action" => "GetQueueAttributes",
               "AttributeName.1" => "All"
             }

      {:ok,
       %HTTPoison.Response{
         body:
           "<?xml version=\"1.0\"?><GetQueueAttributesResponse xmlns=\"http://queue.amazonaws.com/doc/2012-11-05/\"><GetQueueAttributesResult><Attribute><Name>QueueArn</Name><Value>arn:aws:sqs:eu-central-1:123456789012:PaywizardQueue.fifo</Value></Attribute><Attribute><Name>ApproximateNumberOfMessages</Name><Value>1</Value></Attribute><Attribute><Name>ApproximateNumberOfMessagesNotVisible</Name><Value>0</Value></Attribute><Attribute><Name>ApproximateNumberOfMessagesDelayed</Name><Value>0</Value></Attribute><Attribute><Name>CreatedTimestamp</Name><Value>1575360775</Value></Attribute><Attribute><Name>LastModifiedTimestamp</Name><Value>1576669284</Value></Attribute><Attribute><Name>VisibilityTimeout</Name><Value>30</Value></Attribute><Attribute><Name>MaximumMessageSize</Name><Value>262144</Value></Attribute><Attribute><Name>MessageRetentionPeriod</Name><Value>345600</Value></Attribute><Attribute><Name>DelaySeconds</Name><Value>0</Value></Attribute><Attribute><Name>ReceiveMessageWaitTimeSeconds</Name><Value>0</Value></Attribute><Attribute><Name>FifoQueue</Name><Value>true</Value></Attribute><Attribute><Name>ContentBasedDeduplication</Name><Value>true</Value></Attribute></GetQueueAttributesResult><ResponseMetadata><RequestId>d2a83742-e0d2-53b8-a61a-6136c3447eb6</RequestId></ResponseMetadata></GetQueueAttributesResponse>",
         headers: [
           {"x-amzn-RequestId", "d2a83742-e0d2-53b8-a61a-6136c3447eb6"},
           {"Date", "Wed, 18 Dec 2019 12:53:42 GMT"},
           {"Content-Type", "text/xml"},
           {"Content-Length", "1354"}
         ],
         status_code: 200
       }}
    end)

    assert SingulaQueue.attributes() == %{
             approximate_number_of_messages: 1,
             approximate_number_of_messages_delayed: 0,
             approximate_number_of_messages_not_visible: 0,
             content_based_deduplication: true,
             created_timestamp: 1_575_360_775,
             delay_seconds: 0,
             fifo_queue: true,
             last_modified_timestamp: 1_576_669_284,
             maximum_message_size: 262_144,
             message_retention_period: 345_600,
             queue_arn: "arn:aws:sqs:eu-central-1:123456789012:PaywizardQueue.fifo",
             receive_message_wait_time_seconds: 0,
             visibility_timeout: 30
           }
  end

  test "get dlq attributes" do
    MockHTTPClient
    |> expect(:request, fn :post,
                           "https://sqs.eu-central-1.amazonaws.com/",
                           body,
                           _headers,
                           _http_opts ->
      assert URI.decode_query(body) == %{
               "QueueUrl" =>
                 "https://sqs.eu-central-1.amazonaws.com/123456789012/PaywizardDLQ.fifo",
               "Action" => "GetQueueAttributes",
               "AttributeName.1" => "All"
             }

      {:ok,
       %HTTPoison.Response{
         body:
           "<?xml version=\"1.0\"?><GetQueueAttributesResponse xmlns=\"http://queue.amazonaws.com/doc/2012-11-05/\"><GetQueueAttributesResult><Attribute><Name>QueueArn</Name><Value>arn:aws:sqs:eu-central-1:123456789012:PaywizardDLQ.fifo</Value></Attribute><Attribute><Name>ApproximateNumberOfMessages</Name><Value>1</Value></Attribute><Attribute><Name>ApproximateNumberOfMessagesNotVisible</Name><Value>0</Value></Attribute><Attribute><Name>ApproximateNumberOfMessagesDelayed</Name><Value>0</Value></Attribute><Attribute><Name>CreatedTimestamp</Name><Value>1575360775</Value></Attribute><Attribute><Name>LastModifiedTimestamp</Name><Value>1576669284</Value></Attribute><Attribute><Name>VisibilityTimeout</Name><Value>30</Value></Attribute><Attribute><Name>MaximumMessageSize</Name><Value>262144</Value></Attribute><Attribute><Name>MessageRetentionPeriod</Name><Value>345600</Value></Attribute><Attribute><Name>DelaySeconds</Name><Value>0</Value></Attribute><Attribute><Name>ReceiveMessageWaitTimeSeconds</Name><Value>0</Value></Attribute><Attribute><Name>FifoQueue</Name><Value>true</Value></Attribute><Attribute><Name>ContentBasedDeduplication</Name><Value>true</Value></Attribute></GetQueueAttributesResult><ResponseMetadata><RequestId>d2a83742-e0d2-53b8-a61a-6136c3447eb6</RequestId></ResponseMetadata></GetQueueAttributesResponse>",
         headers: [
           {"x-amzn-RequestId", "d2a83742-e0d2-53b8-a61a-6136c3447eb6"},
           {"Date", "Wed, 18 Dec 2019 12:53:42 GMT"},
           {"Content-Type", "text/xml"},
           {"Content-Length", "1354"}
         ],
         status_code: 200
       }}
    end)

    assert SingulaQueue.dlq_attributes() == %{
             approximate_number_of_messages: 1,
             approximate_number_of_messages_delayed: 0,
             approximate_number_of_messages_not_visible: 0,
             content_based_deduplication: true,
             created_timestamp: 1_575_360_775,
             delay_seconds: 0,
             fifo_queue: true,
             last_modified_timestamp: 1_576_669_284,
             maximum_message_size: 262_144,
             message_retention_period: 345_600,
             queue_arn: "arn:aws:sqs:eu-central-1:123456789012:PaywizardDLQ.fifo",
             receive_message_wait_time_seconds: 0,
             visibility_timeout: 30
           }
  end
end
