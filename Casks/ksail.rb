cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.18"
  sha256 arm:          "40e40b1e9580ac903adfcda613945491d9722b5a56a4e0b4ee120a84e621a053",
         arm64_linux:  "f1cae93467b59583c0af6d3f8bfe077cfb14fc19456adc4e075f70a9ea244464",
         x86_64_linux: "55ff2cdae9399ddaf97ad314f47025b0782360bf1ab82b138c90696649a0d961"

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
