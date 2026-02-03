# Homebrew formula for wave-notes-setup
# To calculate SHA256 after creating a GitHub release:
#   curl -sL https://github.com/qbandev/wave-notes-setup/archive/v2.0.0.tar.gz | shasum -a 256
class WaveNotesSetup < Formula
  desc "Configure Wave Terminal with a Warp-like notes system"
  homepage "https://github.com/qbandev/wave-notes-setup"
  url "https://github.com/qbandev/wave-notes-setup/archive/v2.0.0.tar.gz"
  sha256 "6859964eb71a320c2853509ac1232caf23f19ac510ee689cdfd84a7c7916bc2c"
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
