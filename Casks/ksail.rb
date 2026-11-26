cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.40"
  sha256 arm:          "a6bb28d34f60f82935c72dfed5d15d388c9ba09e8b0812172ac05a6725c4f892",
         arm64_linux:  "a66fe02327c59ea284138c54f7de12f0e06b3cdecaf64ffe160206131b832821",
         x86_64_linux: "1828f02e8ffd8883c777b92037fb62b9da01835108f52438240ca899d214ec91"

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
