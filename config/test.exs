import Config

config :griffin_ssg,
  hooks: %{
    before: [
      fn ->
        timestamp = :os.system_time(:millisecond)
        Mix.shell().info("I was called before build: #{timestamp}")
      end
    ],
    after: [
      fn ->
        timestamp = :os.system_time(:millisecond)
        Mix.shell().info("I was called after build: #{timestamp}")
      end
    ]
  }
