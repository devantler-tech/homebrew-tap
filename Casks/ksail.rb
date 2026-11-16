cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.6"
  sha256 arm:          "8cffa6a0950cdbb21c1a56a71c85d90a1fb0951e2fdb5846b4f90f66ec0a25ff",
         arm64_linux:  "b3e8f4b2f7414cb1be1434244361299c9526b2366f3dace93ce4f9ef3e871ad0",
         x86_64_linux: "f9781cc016b44c335d202f7d3e76bcb5bb99625f5df815cf4e57bbb536e39793"

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
