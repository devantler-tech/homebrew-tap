cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.30"
  sha256 arm:          "3e15db3d2e7c443452111cf915366b3108f6b6d0d1d9b3dbbe2d28385fbe042b",
         arm64_linux:  "fb577478bc52527b507ec498e27878af1f74f4221f99d2a769fdd6a25265c4a4",
         x86_64_linux: "2e4df18ef2f5ae497bf23824fdedbbf61ca4878c9909d2c4c995ceb18ad0bc01"

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
