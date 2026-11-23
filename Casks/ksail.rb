cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.12"
  sha256 arm:          "37f1357a04f39f4c0ab8b588098ef287434c4c14815ffd89bb807dd132117fd4",
         arm64_linux:  "2188f2b6acee7736336924daaa1f10cc211761143eb40ca5b8b39f26bd3e5097",
         x86_64_linux: "8dc9a6284ff5823b7ed05e521609f72811e02e2c2f2f20eeb7c9b991ad1d32e5"

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
