class GrokCli < Formula
  desc "Grok coding agent CLI (fork with system-proxy support)"
  homepage "https://github.com/happyfeetw/grok-cli"
  version "1.0.10-1"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v1.0.10-1/grok-cli-1.0.10-1-darwin-arm64.tar.gz"
      sha256 "8fb57a7065c15a224a5088329c257570117efb1fd03a6b73a20b47d028e020a8"
    end
    on_intel do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v1.0.10-1/grok-cli-1.0.10-1-darwin-x64.tar.gz"
      sha256 "64eca0f0a36d456a368d9530d4460c77d8cd27bc3dd3fe85a3a110d1813cd2c9"
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
