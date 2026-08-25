class GrokCli < Formula
  desc "Grok coding agent CLI (fork with system-proxy support)"
  homepage "https://github.com/happyfeetw/grok-cli"
  version "1.0.8-1"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v1.0.8-1/grok-cli-1.0.8-1-darwin-arm64.tar.gz"
      sha256 "5366ab8e58e8ba79ec9b16798d2b2ed6f0fe5c2b92783c9f7d06ccd142e72ae2"
    end
    on_intel do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v1.0.8-1/grok-cli-1.0.8-1-darwin-x64.tar.gz"
      sha256 "22b07ee10a1fa1e245179d4dd094fabc4161e6e6b974fd354e4b6dbcc079ea87"
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
