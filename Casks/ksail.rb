cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.28"
  sha256 arm:          "6f4df5344c4bcc0bd664b9557bcc0bc5b746ebabfa069cc57c13a4aaa4fa7143",
         arm64_linux:  "f312af6a707ef7ed7a80eb8ff24aa84f8342c901690d87d1b414168c01969dad",
         x86_64_linux: "93ff365e5ce1de6dd0e778ecea6e3e491307be98b1dc1605bc400d7ca667feab"

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
