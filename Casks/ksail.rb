cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.37"
  sha256 arm:          "a6c20d28e5184a833ddeb736ecde5d585547a5f46846abd56562f0516f299682",
         arm64_linux:  "e1adcaddfa688642fcde4a9fdc2123f13a1ffacfedd15aa49033fdc86df344b7",
         x86_64_linux: "526a42c7e375b51ec708ea3e9cb6d67efd8b1e45539ad6523a4a15e5d98c2e50"

  on_macos do
    depends_on arch: :arm64
  end

  url "https://github.com/devantler-tech/ksail/releases/download/v#{version}/ksail_#{version}_#{os}_#{arch}.tar.gz"
  name "ksail"
  desc "CLI tool to manage Kubernetes clusters and workloads"
  homepage "https://ksail.devantler.tech/"

  livecheck do
    url :url
    strategy :github_latest
  end

  binary "ksail"
  bash_completion "completions/ksail.bash"
  zsh_completion "completions/ksail.zsh"
  fish_completion "completions/ksail.fish"

  postflight_steps do
    on_macos do
      run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{staged_path}}/ksail"]
    end
  end

  zap :not_required
end
