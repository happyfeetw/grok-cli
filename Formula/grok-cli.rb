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
      sha256 "cf6078d848754549b7b291f74d551f83f4fd8d4bdc6e9a443cecb48b0bc10ac9"
    end
    on_intel do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v0.2.119-1/grok-cli-0.2.119-1-darwin-x64.tar.gz"
      sha256 "f4f0eda6de44d8422afb68e44b3fa384608292fe98082a46717d1c665d70d66a"
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
