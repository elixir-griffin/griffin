%{
  hooks: %{
    before: [
      fn {directories, run_mode, output_mode} ->
        timestamp = :os.system_time(:millisecond)
        Mix.shell().info("Directories before: #{inspect(directories)}")
        Mix.shell().info("Run mode before: #{run_mode}")
        Mix.shell().info("Output mode before: #{output_mode}")
        Mix.shell().info("I was called before build: #{timestamp}")
      end
    ],
    after: [
      fn {directories, results, run_mode, output_mode} ->
        timestamp = :os.system_time(:millisecond)
        Mix.shell().info("Directories after: #{inspect(directories)}")
        Mix.shell().info("Results after: #{inspect(results)}")
        Mix.shell().info("Run mode after: #{run_mode}")
        Mix.shell().info("Output mode after: #{output_mode}")
        Mix.shell().info("I was called after build: #{timestamp}")
      end
    ]
  }
}
