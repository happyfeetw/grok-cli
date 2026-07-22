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
      sha256 "bef846c3ffe01be31d395dc7b6447792627882303e077d81b43a135e5ed74195"
    end
    on_intel do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v0.2.110-1/grok-cli-0.2.110-1-darwin-x64.tar.gz"
      sha256 "cc07ef31ed7eaff8ca3187a4e5815203afbaa444cab4151f1bda0a3bdbc7e814"
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
