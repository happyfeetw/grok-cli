class GrokCli < Formula
  desc "Grok coding agent CLI (fork with system-proxy support)"
  homepage "https://github.com/happyfeetw/grok-cli"
  version "0.2.114-1"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v0.2.114-1/grok-cli-0.2.114-1-darwin-arm64.tar.gz"
      sha256 "197d783053976de1a0c344dc8667e378ba5b454d345e5c31a0f9fc24b7e7fdf5"
    end
    on_intel do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v0.2.114-1/grok-cli-0.2.114-1-darwin-x64.tar.gz"
      sha256 "ce91312f423e72000971ec2a88ced862bf05f9be540122adc6faf7ee5bbfb277"
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
