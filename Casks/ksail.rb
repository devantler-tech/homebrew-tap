cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.1"
  sha256 arm:          "5c69f0f7bbaa22aef3fd1d958a2ad65a677f043d0452679199fe920554fb2a22",
         arm64_linux:  "4895674da91fed7db66ec7a37d239773d6a97a10637c91262e75423e115cf757",
         x86_64_linux: "0f8bffae3a9f8a1930cb6c5f4009d99ce5744ea7506f849075c52c1d67d83177"

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
