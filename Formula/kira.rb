class Kira < Formula
  desc "KeyReply Kira Platform CLI"
  homepage "https://github.com/keyreply/kira-cloudflare"
  version "0.30.5"
  license :cannot_represent

  on_macos do
    on_arm do
      url "https://github.com/keyreply/homebrew-tap/releases/download/v#{version}/kira-#{version}-darwin-arm64.tar.gz"
      sha256 "2050d0a670576c5579226d37316924cf6a6eef9a26a9338a5b5303967aded85a"
    end

    on_intel do
      url "https://github.com/keyreply/homebrew-tap/releases/download/v#{version}/kira-#{version}-darwin-x64.tar.gz"
      sha256 "8bada80e5846ad1428947240f71a0eca66e131721241f10cc93c660437e02e46"
    end
  end

  def install
    bin.install "kira"
    zsh_completion.install "zsh-completions/_kira"
  end

  test do
    assert_match "kira", shell_output("#{bin}/kira --help 2>&1")
    assert_match version.to_s, shell_output("#{bin}/kira --version 2>&1")
  end
end
