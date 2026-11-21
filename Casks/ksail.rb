cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.35"
  sha256 arm:          "e4542fc5bc22d4f3eb43057c15078a1c32775e06396690dc189c7e4080a613b7",
         arm64_linux:  "b650bb70e07059119f6447ed0b7aeeb863b372eba8cdf2bb3e7a8480427c56bd",
         x86_64_linux: "ee274b1cded936215dda8f6182ded59a4033cf242b2118c307bce48535d59d57"

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
