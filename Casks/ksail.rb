cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.1"
  sha256 arm:          "0bfadde84e490e8bdcf3de01e8db94ac007f4fb9a0acd705de3b4d5dbfd871a5",
         arm64_linux:  "702fd1b2a1ed0962dfb0b1ec5444b2df945dee83f98a11528caf6757faa3aaa2",
         x86_64_linux: "597f3e4def1d029cd9a5f961ec93f2b1342e4e7e3dd50a9cb1f95a9fe771595e"

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
