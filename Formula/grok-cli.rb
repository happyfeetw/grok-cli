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
      sha256 "8211083019f46812d81c622414bd48d4eb70b17edbf50bdd48174f0a1f07d994"
    end
    on_intel do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v1.0.12-1/grok-cli-1.0.12-1-darwin-x64.tar.gz"
      sha256 "aa61efc10ad02f7712ab9f95361076fe4dd0e7fa2b1f1acf21dbf03df82f3001"
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
