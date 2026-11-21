cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.29"
  sha256 arm:          "c367834456a759fd62800d888c103956f7ad3e0577c32d2b0d7a7d864adc9d7e",
         arm64_linux:  "69d9acffb045f83e0e1f9cc4af949ce92e2708d535ece5b51796731b0f47196d",
         x86_64_linux: "8eed469603a1bc0abc3ecf5c2005c95036a5026f5e8b147fecfbbc2a0ae1807f"

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
