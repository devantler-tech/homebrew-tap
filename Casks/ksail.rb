cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.14"
  sha256 arm:          "283d6ad58e27f33cd11da5b5e0ae097469efc5cd0d9d74193ff5683afa1c18a9",
         arm64_linux:  "394fe6690f2278d3122a01684ee53e1a87ced5bc62479e452531619b042912b2",
         x86_64_linux: "b854de7f177ccf52e0713bbd0c57c9276e6e42ddac8d1c828522663bb37fe520"

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
