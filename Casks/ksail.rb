cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.47"
  sha256 arm:          "58bfc0f5d442350479c59d05c8b6aa6ea7018bae0a252c99547d66da4c3a139e",
         arm64_linux:  "9461e1ae65aec5822ee08e354a3318cd2189655dbd34c63dc2a76f493063e731",
         x86_64_linux: "cd37af95dc876f79478cc3d23de949db4abdbfd320b66c3ef18874def8cd6b57"

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
