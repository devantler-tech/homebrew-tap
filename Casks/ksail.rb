cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.5"
  sha256 arm:          "e94ef302fcc84dc71a4da5838cbd7b0954b57d41c77fb90056a6164851ff0439",
         arm64_linux:  "c76ff183dd4078577aa2e310eb479787e0f9b3dbcbc7fa96d80c0702947f7bfe",
         x86_64_linux: "307459db8a921c4b5709d4d9c734a89bc62f2b5c03d2f270562444c143bd3130"

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
