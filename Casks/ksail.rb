cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.36"
  sha256 arm:          "9dbbaef65cae2dc7714d915d8c8cd8ed433a8f62dcd2f6bf91ce6b1f6510b9c4",
         arm64_linux:  "9b744afce1e3db0836f073c6cfda95f7e5b862a0f20a897d861e1f1820f1f9a1",
         x86_64_linux: "e71ff311535c188108bd177501b83ac3c68ff3e10ada4b3487900403c5bf1f8e"

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
