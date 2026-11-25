cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.30"
  sha256 arm:          "142d10727be297b38e699c62bd21a721d2fc163e1f8e11776b1dd54036631e98",
         arm64_linux:  "c89e294dc12f1a5bcd6c02a0376c72ffe16a885f200d125420c6ab1dfe456cf7",
         x86_64_linux: "dc05aa51140e4d0ae9fc541da4d2a8b1531b8ea3ec272a609f12fb90be21de52"

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
