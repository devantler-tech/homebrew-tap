cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.35"
  sha256 arm:          "f00e0a4168a366dc8a7a0c4430b7863850008aaaf0d623d44c65e519fcc430a3",
         arm64_linux:  "f89d3ab80f8c14a59b55dffb6f303316ffc6715c46a4d28ed5c9a574d0a9f770",
         x86_64_linux: "85da0accd98fc350c2242f7d31da17d2ac5d4e3eeb945d5cb5996bc355733988"

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
