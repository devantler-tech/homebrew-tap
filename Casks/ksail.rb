cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.40"
  sha256 arm:          "4207a92d3fe463a3d53ec820e5d7ad1f870f30ad79d4104aa634555c8ee63ba5",
         arm64_linux:  "4dd16203f50ed3b9a31dd64e0af5e35195c4b1ff034482ad8d10b191b791213c",
         x86_64_linux: "d0c1e3df83752f7d78905a1eec5623d4639325bd83f985a15c992373aebf51a5"

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
