cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.19"
  sha256 arm:          "7cd6584f9fb30618f7a0f6cd114d10a531fa3352df971d606918dc5a1e9d2ffc",
         arm64_linux:  "07df16293dbbdd94638ade0bcb02da240026367484ca91cc257396550618b362",
         x86_64_linux: "787e641007e2ce132bed9c83f12a1b12226aae0057d0c4e877b2872afd6791f0"

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
