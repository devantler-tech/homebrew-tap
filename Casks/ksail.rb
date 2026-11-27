cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.48"
  sha256 arm:          "629a203fa7906fb894a543b516cb6787da77da3c6a10c6f03f4e87ad16fbefaf",
         arm64_linux:  "bb6658b3d48083e8dc9919c80d6f9deb3f9cf5413e9d8412a8ccbed91fe47d15",
         x86_64_linux: "4c57c6b4816556ea5dff4c2f9c1bef8ee8abd8d9b1fd593e545196edfdfefd80"

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
