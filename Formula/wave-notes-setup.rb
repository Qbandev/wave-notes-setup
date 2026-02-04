# Homebrew formula for wave-notes-setup
# To calculate SHA256 after creating a GitHub release:
#   curl -sL https://github.com/qbandev/wave-notes-setup/archive/v2.0.1.tar.gz | shasum -a 256
class WaveNotesSetup < Formula
  desc "Configure Wave Terminal with a Warp-like notes system"
  homepage "https://github.com/qbandev/wave-notes-setup"
  url "https://github.com/qbandev/wave-notes-setup/archive/v2.0.1.tar.gz"
  sha256 "031f6f22624765a1b315dec844e09f8a787e3c315d53f40c274dac5a67cda89f"
  license "MIT"

  depends_on "jq"

  def install
    bin.install "install.sh" => "wave-notes-setup"
    bin.install "uninstall.sh" => "wave-notes-uninstall"
  end

  def caveats
    <<~EOS
      To complete setup, run:
        wave-notes-setup

      To uninstall the Wave configuration:
        wave-notes-uninstall

      For custom configuration, create ~/.wave-notes.conf:
        NOTES_DIR="$HOME/Documents/WaveNotes"
        BIN_DIR="$HOME/bin"
    EOS
  end

  test do
    assert_match "wave-notes-setup v", shell_output("#{bin}/wave-notes-setup --version")
  end
end
