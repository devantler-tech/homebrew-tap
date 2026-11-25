cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.29"
  sha256 arm:          "3c1645db246477bc91ece48a3dd0cdc0e6be55dab4254e6c135126d446d0a3a0",
         arm64_linux:  "f2ff21cfdd1e7c32223520de0bff9ea7a8b356271f8cfffb627a733da76b604f",
         x86_64_linux: "4e82baf9964d1747e425a862c11da4f1cb1d68a13c7927beca1645717b05eed8"

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
