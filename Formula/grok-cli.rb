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
      sha256 "a08a686920a62eb2541c61f6a2ef92e4e188658331b10d31aa55727cc5b0bd94"
    end
    on_intel do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v1.0.6-1/grok-cli-1.0.6-1-darwin-x64.tar.gz"
      sha256 "fd5c45a894af42623c2a355e3f260c187d397cc59462ee16a1b5d1d85600b518"
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
