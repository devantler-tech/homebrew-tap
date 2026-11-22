cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.45"
  sha256 arm:          "bcaf91002137802d5e23c06ff0519a8b4de9b96aa06510c877b39c8698936ed0",
         arm64_linux:  "abd32b9f25396715c6406185015c33e5cab61dc60cd0cd6d0849b3c74f109c12",
         x86_64_linux: "4b3405566519bf0cdb9c6539fbf0b469367f26664ce817e8a083689d3aa83ad6"

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
