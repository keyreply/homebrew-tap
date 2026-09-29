class Kira < Formula
  desc "KeyReply Kira Platform CLI"
  homepage "https://github.com/keyreply/kira-cloudflare"
  version "0.30.68"
  license :cannot_represent

  on_macos do
    on_arm do
      url "https://github.com/keyreply/homebrew-tap/releases/download/v#{version}/kira-#{version}-darwin-arm64.tar.gz"
      sha256 "5be0c5781d6c5cbf585265f5131f72815b2b246f9fc3d56ce283d63ddf8c0bc4"
    end

    on_intel do
      url "https://github.com/keyreply/homebrew-tap/releases/download/v#{version}/kira-#{version}-darwin-x64.tar.gz"
      sha256 "318503ca51dbd4f246d415c5568b80ac813c2b38a21638999594e7035c49719c"
    end
  end

  def install
    bin.install "kira"
    unless quiet_system "/usr/bin/codesign", "--verify", "--strict", bin/"kira"
      system "/usr/bin/codesign", "--force", "--sign", "-", "--identifier", "com.keyreply.kira", bin/"kira"
    end
    zsh_completion.install "zsh-completions/_kira"
  end

  def post_install
    ENV["KIRA_DISABLE_AUTO_UPDATE"] = "1"
    ENV["KIRA_DISABLE_SKILL_REFRESH"] = "1"
    system bin/"kira", "chatgpt-skills", "install", "--force"
    system bin/"kira", "claude-skills", "install", "--force"
    begin
      system bin/"kira", "tenant", "install-prompt"
    rescue StandardError => e
      opoo "Could not configure shell prompt integration: #{e.message}"
    end
  end

  def caveats
    <<~EOS
      Shell prompt integration:
        kira tenant install-prompt     # configure (already ran)
        kira tenant install-prompt --uninstall  # remove

      Kira's ChatGPT/Codex and Claude skill packs are force-refreshed
      during installation and upgrade. Existing bundled kira-* skill
      directories are replaced; unrelated custom skills are untouched.

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
