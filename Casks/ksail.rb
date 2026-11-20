cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.27"
  sha256 arm:          "4e2a0fcf597ea607164192fd8f20d340123fcbb28034d52a3dafd65664208888",
         arm64_linux:  "5773c38787da8fa0c7ec7e2a2a1ea801ade080f465ebb99a6fcfe4f55087f366",
         x86_64_linux: "4fda2a97cd9f5178660b8a4d321d259f31d405cabf7a646785d690c7047017e5"

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
