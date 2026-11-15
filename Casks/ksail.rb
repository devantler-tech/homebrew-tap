cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.214.0"
  sha256 arm:          "4fb8c216e97cb0108f35f09f404a3e27f4513859d7d5dffa617cc4f98445484c",
         arm64_linux:  "fde1adfbc7fbd6e615f22faa837204c2597d839df3d3cc175c167e2cbaca99c3",
         x86_64_linux: "9d4638a7f655ccc7684b430c45dadce35f53a1bca463f498c5067ca30a7af2dd"

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
