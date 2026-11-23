cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.8"
  sha256 arm:          "b2d2d67b9325be9b306d7238668f3c33c3ed2f61c18f74a3e3fa8206ff069770",
         arm64_linux:  "8ba582c1c54851dabf50358acb1d88f5e4b4cc43485a1d951f880e792d668918",
         x86_64_linux: "5feecae0fe18a2a19611fbeb2a4b99f156a9a97ca514df4abd243834901d3d02"

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
