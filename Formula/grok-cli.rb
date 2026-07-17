class GrokCli < Formula
  desc "Grok coding agent CLI (fork with system-proxy support)"
  homepage "https://github.com/happyfeetw/grok-cli"
  version "0.1.224"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v0.1.224/grok-cli-0.1.224-darwin-arm64.tar.gz"
      sha256 "a4ead2c65efdeab5652fa90b7e87d4b5f1cbf6e29fc19bcd6f83327cdb7b82f4"
    end
    on_intel do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v0.1.224/grok-cli-0.1.224-darwin-x64.tar.gz"
      sha256 "dd85230dc89b0adb2222cae68b9d457c8328238c9337cf3ca1e4bc56ddaec1f2"
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
