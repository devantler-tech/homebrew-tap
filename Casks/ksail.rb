cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.49"
  sha256 arm:          "275cb4792138c71dd9795ceeb3bcfce5daf15ee6f7b0eba39ec5d687395196a3",
         arm64_linux:  "457514863873686c4209f3e78004f81b65634b476f1affc93e36bfdaa05ca931",
         x86_64_linux: "98cc461a3ad643b9c50cc11a17aee9531ca10cafdf4d64bdb79f08d2431a3445"

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
