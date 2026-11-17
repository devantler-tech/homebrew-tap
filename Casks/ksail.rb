cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.9"
  sha256 arm:          "2c29c66890d87bac8124435cb96442a085203240fa3e726dcc4c3054b82f06fb",
         arm64_linux:  "883ef70a53575a4fef05348d07041af4deae1b24d43d1a2d24b3b80923707118",
         x86_64_linux: "9f3bc665fd425216b51b022a0b6c51b3ef42537dda709b8286cecb5dca4d82fe"

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
