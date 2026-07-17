class GrokCli < Formula
  desc "Grok coding agent CLI (fork with system-proxy support)"
  homepage "https://github.com/happyfeetw/grok-cli"
  version "0.1.223"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v0.1.223/grok-cli-0.1.223-darwin-arm64.tar.gz"
      sha256 "124a92c6022918c46d60201b042b5c49939a6e4c426091ede710da686f3e56fb"
    end
    on_intel do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v0.1.223/grok-cli-0.1.223-darwin-x64.tar.gz"
      sha256 "1882d778ddeb6bffae92b6070852efcbca408e08d5a563ae5f4183d446318a3b"
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
