cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.31"
  sha256 arm:          "6655b15280b48ba4067593b61fe8264068b1d4a3c664c2d36806a5a51f208689",
         arm64_linux:  "11f45d58986e47076151312ef5d939443948ef2dfc1487db03f3d05dfdc54712",
         x86_64_linux: "f3574737e1378a0dcd5a9d6b23b16c9640d3a8c65fde363be6cb9a9ceb24bcf8"

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
