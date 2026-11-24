cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.216.21"
  sha256 arm:          "2b8f133945c51b4dc3cad30039499fe44f4c8d81fad948ca5c3a774ecbab03b6",
         arm64_linux:  "e80c3401ae258d3558395733e942c9896ff985a282dcf5697abd28f4ee2575fe",
         x86_64_linux: "36ac7915cab6ba24145a64fa1b91bafc735408870b2306fdaa49d0f0e1b35bf2"

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
