cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.213.43"
  sha256 arm:          "c09703177eb0b5d2a4e879983c68861c41abdf46e3f9ceb20f8704c58862ab71",
         arm64_linux:  "46391386ba8d5791580d797d0c6ab83c0565e7aa54c28b4f34d4f9f659f65107",
         x86_64_linux: "83f7c3f21bfee8a4a6b44846beb90449b5bfc94b30b88daf1a36e3dbb7eaa84d"

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
