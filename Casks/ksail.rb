cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.15"
  sha256 arm:          "8b52a92c71f248937a96a7173b90f7bdd143233e91c014d1411c7b16effcdf29",
         arm64_linux:  "9e0a3f74f8a1f130a6576b9d83de1850fd0490819c4f9bb670bf14473c68e104",
         x86_64_linux: "b9af4e972e0afe06270caa0416dcda86aa1e0211517ba8e55825ada37981d445"

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
