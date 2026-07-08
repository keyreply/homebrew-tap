class Kira < Formula
  desc "KeyReply Kira Platform CLI"
  homepage "https://github.com/keyreply/kira-cloudflare"
  version "0.30.11"
  license :cannot_represent

  on_macos do
    on_arm do
      url "https://github.com/keyreply/homebrew-tap/releases/download/v#{version}/kira-#{version}-darwin-arm64.tar.gz"
      sha256 "12b89a03e77b3392066d04c38899e70ad9a6ccd443fbb56d147f2200b28d8c3c"
    end

    on_intel do
      url "https://github.com/keyreply/homebrew-tap/releases/download/v#{version}/kira-#{version}-darwin-x64.tar.gz"
      sha256 "a3888d40ff6d4d11bccc60739a06fb0240d91fa4ed73c38804e0f93769bef23c"
    end
  end

  def install
    bin.install "kira"
    zsh_completion.install "zsh-completions/_kira"
  end

  def post_install
    system bin/"kira", "tenant", "install-prompt"
  rescue StandardError => e
    opoo "Could not configure shell prompt integration: #{e.message}"
  end

  def caveats
    <<~EOS
      Shell prompt integration:
        kira tenant install-prompt     # configure (already ran)
        kira tenant install-prompt --uninstall  # remove

      Restart your shell or run:
        source ~/.zshrc   # zsh
        source ~/.bashrc  # bash
    EOS
  end

  test do
    assert_match "kira", shell_output("#{bin}/kira --help 2>&1")
    assert_match version.to_s, shell_output("#{bin}/kira --version 2>&1")
  end
end
