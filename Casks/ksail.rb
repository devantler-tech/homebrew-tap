cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.37"
  sha256 arm:          "f3555298091aa04773950b09a4be57e37a696f353287b1c0eccf7ef47768d4d6",
         arm64_linux:  "f0fa7b82989ebb82f581dd8ec3f395f829ddd7c26940dcbbefca16c51d8ab014",
         x86_64_linux: "9106e82696b030fb16a0b7177801d4b04d08f73c729348166fcd6a467440d652"

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
