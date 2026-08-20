class GrokCli < Formula
  desc "Grok coding agent CLI (fork with system-proxy support)"
  homepage "https://github.com/happyfeetw/grok-cli"
  version "0.2.119-1"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v0.2.119-1/grok-cli-0.2.119-1-darwin-arm64.tar.gz"
      sha256 "55311790740e00d4c8082b2bbec8f24dc78294202e515a30a1b602a29ef237fc"
    end
    on_intel do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v0.2.119-1/grok-cli-0.2.119-1-darwin-x64.tar.gz"
      sha256 "9645e35136e2f19276aec50c5c7e89ebccc003e1120733473ed0c6c4723f9636"
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
