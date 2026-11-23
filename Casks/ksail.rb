cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.10"
  sha256 arm:          "bf31dccc06416493de221b9e290422162753e00d21bfae19a3397f1f7f7aea32",
         arm64_linux:  "cdedaa7be1cf43909fd9164f8cc699730dfd9cfe0d8961977217345bce97fbde",
         x86_64_linux: "e1c5e3183422513c7308e77a62750739d6d6dbab2d259b965de79c38b993e0e0"

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
