class Kira < Formula
  desc "KeyReply Kira Platform CLI"
  homepage "https://github.com/keyreply/kira-cloudflare"
  version "0.30.6"
  license :cannot_represent

  on_macos do
    on_arm do
      url "https://github.com/keyreply/homebrew-tap/releases/download/v#{version}/kira-#{version}-darwin-arm64.tar.gz"
      sha256 "8219bc665543b3f07e60e71618e1917fab5533b0788d16e2b9db7c6ed4abb0fa"
    end

    on_intel do
      url "https://github.com/keyreply/homebrew-tap/releases/download/v#{version}/kira-#{version}-darwin-x64.tar.gz"
      sha256 "e6b500cbb92db7540889f718858189b456f844022905ce6a29654e2a593583d3"
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
