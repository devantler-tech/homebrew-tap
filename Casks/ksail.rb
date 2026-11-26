cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.41"
  sha256 arm:          "a23da5b97b1275dc00e6090b9a16388ef4570377905b1303dfec337011d81b8c",
         arm64_linux:  "b98ece12c95e3a7cdc74f7afc387cfe69cdede299b1c918a8a1a17b2c56ab999",
         x86_64_linux: "2aeb2e518f9c542e900a2f3f876566d6365e9452acbc805674f4e9cb83b3ea80"

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
