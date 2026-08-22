class GrokCli < Formula
  desc "Grok coding agent CLI (fork with system-proxy support)"
  homepage "https://github.com/happyfeetw/grok-cli"
  version "1.0.6-1"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v1.0.6-1/grok-cli-1.0.6-1-darwin-arm64.tar.gz"
      sha256 "35c3037d0143a536797d4c75441fb2a26fa705d34dbf69e29f48ea81ee85415b"
    end
    on_intel do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v1.0.6-1/grok-cli-1.0.6-1-darwin-x64.tar.gz"
      sha256 "b8f30c471f1dd0cd7a5c90a3ec500ff4dc3a0f624315440e5e2396a6740831e8"
    end
  end

  def install
    # Ship as grok-cli so it does not shadow the official grok command.
    bin.install "grok-cli"
  end

  test do
    assert_predicate bin/"grok-cli", :exist?
  end
end
