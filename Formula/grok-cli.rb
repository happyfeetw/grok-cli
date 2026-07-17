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
      sha256 "997a673ea7635bb9d3a34b0d12d0bad226e5556ee0161d4c7279b433970801e3"
    end
    on_intel do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v0.1.225/grok-cli-0.1.225-darwin-x64.tar.gz"
      sha256 "23d50f3ac83ff6b3e22b1ef66cacc3f1108f6d5e7776f52ab9ccf3705200da5c"
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
