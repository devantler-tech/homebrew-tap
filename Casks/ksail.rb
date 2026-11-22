cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.38"
  sha256 arm:          "46c7af3f0658f43dc9bdf18cb78845c028246fb3bde3f30ac7fccc828c6e9094",
         arm64_linux:  "b71fba8f3a08a172512d8ecdc50df91c2ddd4b4b58fd070bfbe1d2b182b9af47",
         x86_64_linux: "6113f55238a5c553c1a8a18a22255476041cb1b87117bd2a8214a5848b781be2"

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
