# Homebrew formula for wave-notes-setup
# To calculate SHA256 after creating a GitHub release:
#   curl -sL https://github.com/qbandev/wave-notes-setup/archive/v2.0.2.tar.gz | shasum -a 256
class WaveNotesSetup < Formula
  desc "Configure Wave Terminal with a Warp-like notes system"
  homepage "https://github.com/qbandev/wave-notes-setup"
  url "https://github.com/qbandev/wave-notes-setup/archive/v2.0.2.tar.gz"
  sha256 "b24bba21fcf30edc567fc3e24bf1a70d6e9dd6efc05ab64f80999f1278516fe4"
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
