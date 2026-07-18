class GrokCli < Formula
  desc "Grok coding agent CLI (fork with system-proxy support)"
  homepage "https://github.com/happyfeetw/grok-cli"
  version "0.2.105-1"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v0.2.105-1/grok-cli-0.2.105-1-darwin-arm64.tar.gz"
      sha256 "f4ff672c25197739434bd4121ea6cbfbeddb8af0d8ec869943a26903ef0e7c9f"
    end
    on_intel do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v0.2.105-1/grok-cli-0.2.105-1-darwin-x64.tar.gz"
      sha256 "c111eccdb61c29c81788d90ba55b1615b61b2a978e7976cedb0c8ee6136c2089"
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
