cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.42"
  sha256 arm:          "8ca2ab38a353c6bb772fc8176217faceaa2d1eeb865a96c6568903cc9ed7b52b",
         arm64_linux:  "a3baa9530846fb160e56d561048095ba53afdf5844a118a0b16636bcaec00ddc",
         x86_64_linux: "b6b64ae2171942e36db1381fba592132ce5dbb66efd99e7875f19a2f4f0fa8e3"

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
