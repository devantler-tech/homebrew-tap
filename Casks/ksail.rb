cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.39"
  sha256 arm:          "d65ec24a8ee32c11b4524687b7dd86d0533343cbe88426d84918d1a6529ff1cd",
         arm64_linux:  "7142489146e28bf1df530ef2a4582a9d7a21a2ab3e69fa3a81ae1920eb938b22",
         x86_64_linux: "5cdf46c3fc1bddfb80ffca9f26aeb7b1cd3dd9786df7ebbef3eb68090cf7185a"

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
