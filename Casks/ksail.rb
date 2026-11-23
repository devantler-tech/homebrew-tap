cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.3"
  sha256 arm:          "768620d9a5e93438dd64283178f89c0250fd4b77ecf960e35177127a1e72944b",
         arm64_linux:  "cab52e70152e4f94243f09d6b00c8742e80a343552e387ea954527338ece0430",
         x86_64_linux: "e2579f6e2dfca53b595f43d4286bc1b1c4fc9bed098cd9266f3b444c55f96cc6"

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
