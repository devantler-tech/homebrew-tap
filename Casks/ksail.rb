cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.0"
  sha256 arm:          "303b698c664b92218973cf54f0e321e74315e1e09f0c3d76fa0e6abe7c400f3b",
         arm64_linux:  "b9b6271fa76a3446351bd92796a82cb5315b9516fa47224b253f495c2e734260",
         x86_64_linux: "be0273bb6eac6a779d23f07ba67f27814815d4c92888b8cd2f8afb644bb2a1ab"

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
