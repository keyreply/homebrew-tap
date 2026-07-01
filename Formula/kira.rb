class Kira < Formula
  desc "KeyReply Kira Platform CLI"
  homepage "https://github.com/keyreply/kira-cloudflare"
  version "0.30.10"
  license :cannot_represent

  on_macos do
    on_arm do
      url "https://github.com/keyreply/homebrew-tap/releases/download/v#{version}/kira-#{version}-darwin-arm64.tar.gz"
      sha256 "8c229ffb3741fbbfbec278184f50e09e01c83dd2e7280e0f940f5f0b6e12ca01"
    end

    on_intel do
      url "https://github.com/keyreply/homebrew-tap/releases/download/v#{version}/kira-#{version}-darwin-x64.tar.gz"
      sha256 "2f8c70eb4ca78a4a5d19c5f91821308e743e05e85f3de6edcab09c0d4b68d85a"
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
