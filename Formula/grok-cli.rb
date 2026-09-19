class GrokCli < Formula
  desc "Grok coding agent CLI (fork with system-proxy support)"
  homepage "https://github.com/happyfeetw/grok-cli"
  version "1.0.12-1"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v1.0.12-1/grok-cli-1.0.12-1-darwin-arm64.tar.gz"
      sha256 "cb51f37bad3d1848fc07d30453323582d892461a69ea7940d662e305e18ca2c6"
    end
    on_intel do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v1.0.12-1/grok-cli-1.0.12-1-darwin-x64.tar.gz"
      sha256 "320f9e581af566ac429d4b85b56bb8806cf6bbfebe2ff705d8ef1ef915e38c75"
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
