class GrokCli < Formula
  desc "Grok coding agent CLI (fork with system-proxy support)"
  homepage "https://github.com/happyfeetw/grok-cli"
  version "0.1.225"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v0.1.225/grok-cli-0.1.225-darwin-arm64.tar.gz"
      sha256 "ef6c5eac331dd14cd68cb68175a4aca4e481c9d6cffa6c5829347f1cce42ea43"
    end
    on_intel do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v0.1.225/grok-cli-0.1.225-darwin-x64.tar.gz"
      sha256 "db56be5b9a927ff4f260ab07d3260a304d68f8cdb3cce4eb92a09d149ad18820"
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
