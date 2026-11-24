cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.20"
  sha256 arm:          "551fa2cbda35f76f84df36fdf45c7669257763b545a4002f913b6bf9e30a382c",
         arm64_linux:  "16784e846df6e6327f084f84e81775c807b00015d6375b5f74fc0c3a25e7d4d9",
         x86_64_linux: "ad6a91ed169765ede0447db1945ce13462d7e9a4b9d16151ecb72b74c228ed1f"

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
