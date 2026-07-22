class GrokCli < Formula
  desc "Grok coding agent CLI (fork with system-proxy support)"
  homepage "https://github.com/happyfeetw/grok-cli"
  version "0.2.110-1"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v0.2.110-1/grok-cli-0.2.110-1-darwin-arm64.tar.gz"
      sha256 "fc82b97e4a83d92f2336b8ed4097a0c570d5765f2f56d794727d304480fd7c04"
    end
    on_intel do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v0.2.110-1/grok-cli-0.2.110-1-darwin-x64.tar.gz"
      sha256 "a4005d1d733c7762e0bf500f8c1b48d64cd5938b1e2c1de663d630681d867f80"
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
