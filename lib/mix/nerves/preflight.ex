defmodule Mix.Nerves.Preflight do
  @fwup_semver "~> 1.2.5 or ~> 1.3"

  def check! do
    {_, type} = :os.type()
    check_requirements("fwup")
    check_requirements("mksquashfs")
    check_host_requirements(type)
    Mix.Task.run("nerves.loadpaths")
  end

  def check_requirements("mksquashfs") do
    case System.find_executable("mksquashfs") do
      nil ->
        Mix.raise(missing_package_message("squashfs"))

      _ ->
        :ok
    end
  end

  def check_requirements("fwup") do
    case System.find_executable("fwup") do
      nil ->
        Mix.raise(missing_package_message("fwup"))

      _ ->
        with {vsn, 0} <- System.cmd("fwup", ["--version"]),
             vsn = String.trim(vsn),
             {:ok, req} = Version.parse_requirement(@fwup_semver),
             true <- Version.match?(vsn, req) do
          :ok
        else
          false ->
            {vsn, 0} = System.cmd("fwup", ["--version"])

            Mix.raise("""
            fwup #{@fwup_semver} is required for Nerves.

            You are running #{vsn}.
            Please see https://hexdocs.pm/nerves/installation.html#fwup
            for installation instructions
            """)

          error ->
            Mix.raise("""
            Nerves encountered an error while checking host requirements for fwup
            #{inspect(error)}
            Please open a bug report for this issue on github.com/nerves-project/nerves
            """)
        end
    end
  end

  def check_host_requirements(:darwin) do
    case System.find_executable("gstat") do
      nil ->
        Mix.raise(missing_package_message("gstat (coreutils)"))

      _ ->
        :ok
    end
  end

  def check_host_requirements(_), do: nil

  defp missing_package_message(package) do
    """
    #{package} is required by the Nerves tooling.

    Please see https://hexdocs.pm/nerves/installation.html#host-specific-tools
    for installation instructions.
    """
  end

end
