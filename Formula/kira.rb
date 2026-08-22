class Kira < Formula
  desc "KeyReply Kira Platform CLI"
  homepage "https://github.com/keyreply/kira-cloudflare"
  version "0.30.24"
  license :cannot_represent

  on_macos do
    on_arm do
      url "https://github.com/keyreply/homebrew-tap/releases/download/v#{version}/kira-#{version}-darwin-arm64.tar.gz"
      sha256 "302d408a3ed59b1a59ae576d4ee9fbea439e3b075ac72e3ed0bdd6cecd0cd6f0"
    end

    on_intel do
      url "https://github.com/keyreply/homebrew-tap/releases/download/v#{version}/kira-#{version}-darwin-x64.tar.gz"
      sha256 "d5b84d55c1756b772f570d63ff114add4921af0409bc7ff7c18ef8dafc01e50e"
    end
  end

  def install
    bin.install "kira"
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
