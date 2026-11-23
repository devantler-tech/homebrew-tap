cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.4"
  sha256 arm:          "96fb4915e2ea2671a69ac4727efd561948e3ef4ef3e974b7c9e9a56068361c0c",
         arm64_linux:  "0e9f53d38cce62b75fced953b1b20647290c7669606ea906b7bbf537f705a2a1",
         x86_64_linux: "cd00a3ae3fdc564cfa5abc5079d73050ebe01cf763d89e7c7eb1e64d46554fc0"

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
