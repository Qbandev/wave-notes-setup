# Homebrew formula for wave-notes-setup
# To calculate SHA256 after creating a GitHub release:
#   curl -sL https://github.com/qbandev/wave-notes-setup/archive/v1.0.0.tar.gz | shasum -a 256
class WaveNotesSetup < Formula
  desc "Configure Wave Terminal with a Warp-like notes system"
  homepage "https://github.com/qbandev/wave-notes-setup"
  url "https://github.com/qbandev/wave-notes-setup/archive/v1.0.0.tar.gz"
  # TODO: Replace with actual SHA256 after creating GitHub release v1.0.0
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"
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
