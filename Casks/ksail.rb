cask "ksail" do
  arch arm: "arm64", intel: "amd64"
  os macos: "darwin", linux: "linux"

  version "7.215.16"
  sha256 arm:          "bbfc7bb295912dbde242a839202f83b4b08d4cebcbfea91e4cb584509fd40692",
         arm64_linux:  "4b34b69e56d02dc7bd4ee9329bcf08cb106803e74adf12b277f9bb1d5bec4b3b",
         x86_64_linux: "617b50fd5d1f341cbfb057e654f92df8f140fb1fd22035e51796589d14893a44"

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
