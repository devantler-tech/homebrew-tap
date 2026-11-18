cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.13"
  sha256 arm:          "c43cec73256f188802d378ccd92410c473460716680f63c3ea590c1a15ba6ccd",
         arm64_linux:  "ff2f190668378d2e97b5df08fc3dc1a390ac53d533eeea0b2bcb827df89d5ae1",
         x86_64_linux: "f9f31745865eb08f4af42ea6bbb06aea9a1e8ac81f857a18a07770994ad723bc"

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
