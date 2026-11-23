cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.9"
  sha256 arm:          "44d1610921a81db2b4049a1b59edb4489c0fb915544095bf932aa65c2177793f",
         arm64_linux:  "d1f789eddd67d09582ae78cc5ca63a813f5fe04ad8c0ab5dec16802db6410070",
         x86_64_linux: "d01a3a59a65b3eab702b790efc28a8a01b2b14dead1209d9effa3ee06c1e7fc2"

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
