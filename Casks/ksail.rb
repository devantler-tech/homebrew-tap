cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.43"
  sha256 arm:          "c0259e7163e0175204c9555568e872d01999fc735140471fc02f272bbf25a1c0",
         arm64_linux:  "f5ab192442514c9bd50aa9c3504605a755a3a60b3f15b1dec5c1e735ba2b3db8",
         x86_64_linux: "6e26a6bd4a4569b9853662ccc2f7e40cf78c722bf9f00fb8cb715c3deb5d3c05"

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
