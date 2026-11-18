cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.12"
  sha256 arm:          "a837b1f95fcd97cd4a03162eb99e9dd4c9d01f5e797b242fd382c1e07f00d5f3",
         arm64_linux:  "6814ea81ca3890340496e9db25fb73585ff72d4045518e9079ebc4cdb63a6ddf",
         x86_64_linux: "2297b4bdfab28b54a80764814a04c94c11cc3c4525052bb2498e8ef13c14949e"

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
