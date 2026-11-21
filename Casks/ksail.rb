cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.33"
  sha256 arm:          "4fea88fd7d01b1d3eef0f505a775dabc2667925366745f18649a7eb5b62ff458",
         arm64_linux:  "d761b35d905685c01cd734bc3a6d068f7c8b833bda2f5bd720c96a0587f9a9e5",
         x86_64_linux: "496f3811b233a32c5b12a8ad678098e59e692f1f564d9253a9c667efd456043b"

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
