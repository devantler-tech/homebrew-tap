cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.34"
  sha256 arm:          "9238caa17763c242bd351701e7af666435f0417c0961233f26bdf44b0ba1f22e",
         arm64_linux:  "bbd979c2a4f2dbc881e0147513fab3377038567f291e4513d37e4d053d4455fb",
         x86_64_linux: "9ae3039d2104b75eefe42f381130d98a5a89ef990e42f4164dac7e2b4808149d"

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
