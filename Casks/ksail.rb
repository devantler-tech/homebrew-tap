cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.38"
  sha256 arm:          "37ba6a04d76c55ae3439ac951d9e0445ae97a76ce24a01fb55968e5859af7092",
         arm64_linux:  "1740c58238d2a7b33e9ff19f715d5ed59ec1402503f13fcaf46356b29e8d5140",
         x86_64_linux: "a644ad331ff86b42ca6caa6d9d1321599c7fe03533c5442f4fe786fccbdc2515"

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
