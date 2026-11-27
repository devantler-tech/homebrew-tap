cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.46"
  sha256 arm:          "e0b0172f56efcccada1957397d9705c10aa3388bbb261ac2a98587b1f431a45a",
         arm64_linux:  "020ff2ce7edd7b9c18e98738ba5101c98815a42199fb30a4f5082e1601b2b172",
         x86_64_linux: "afcd17c32f3bd63bf159a1394b6ff887f9f2e86c87374ca5e59abb7a532b542f"

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
