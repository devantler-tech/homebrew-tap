cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.20"
  sha256 arm:          "d6323f54f8daebf3b4071dca6a5553e1f7db0fef5065e6e6bd913b43e8d18111",
         arm64_linux:  "d1bd818a8011d5e8563a94f1d4ac5c413560aafceeb21f5ab1c73839caf7a691",
         x86_64_linux: "261e0a3abb3bc3366603540141694caec076103fc1112135493f50b8c583b5ac"

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
