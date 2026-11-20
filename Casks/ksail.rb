cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.24"
  sha256 arm:          "9d1ab6504ccb129ab0c905ce7ac3eb160f0208224d7c3050cb9497e133774540",
         arm64_linux:  "048fbe75614f80e9aea6df1bbfb7b351926d9fca36a6294b7d51a65aa0a4d5fc",
         x86_64_linux: "f0e85f28f7a254e1d50e76abe45e2d85cfb044249c8eb34eeb5ca04a76878b03"

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
