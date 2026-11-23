cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.7"
  sha256 arm:          "f3cf5c2395a9745e892781430a6f621ef69463fc7b3a1f31f80418750f8935f1",
         arm64_linux:  "a8af21d5649a4147b4d920e5b27d454cd173719475e4b9e4174f133f304af85d",
         x86_64_linux: "053ef8611768b65cd68136cc8678380c5b26831116b4a1c84b0aae7907d040d9"

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
