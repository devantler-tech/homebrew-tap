cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.11"
  sha256 arm:          "459975ee478829c31e8da8fb7a9c0a4dac47632816f9672158aa78b3642612ed",
         arm64_linux:  "aeb90e11dad92ca55baa8486e0fdf4787c3d91e6df3aa3f43b3ed1114c3b4c63",
         x86_64_linux: "0f66b02584efe51f0da8b4093f95bbec6301a19c33f98d690743b0fc77ab04c5"

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
