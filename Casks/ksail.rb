cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.19"
  sha256 arm:          "1d1fc462249c25d3c772c81032a103a597f94157bfa6b6762c975a3c48422be4",
         arm64_linux:  "ff116462cdfea6c2aaf877137f59f72c579bab73bfa51f13a1f321bcaca600a0",
         x86_64_linux: "c74305ea8b0a926a67155e52f84b3185ddd9870996e35dd579e331a577acaac9"

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
