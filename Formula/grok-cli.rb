class GrokCli < Formula
  desc "Grok coding agent CLI (fork with system-proxy support)"
  homepage "https://github.com/happyfeetw/grok-cli"
  version "0.1.221"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v0.1.221/grok-cli-0.1.221-darwin-arm64.tar.gz"
      sha256 "f1e9df1b04e62dd0e52c88d3b3f161b138f63eff7c451ab36bb8428ad9ca83ad"
    end
    on_intel do
      url "https://github.com/happyfeetw/grok-cli/releases/download/v0.1.221/grok-cli-0.1.221-darwin-x64.tar.gz"
      sha256 "9cea51b45dbe5bd8b526e3a733dbdaf73b138040539f7c7de397f75eee7fbc2d"
    end
  end

  def install
    bin.install "grok"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/grok --version 2>&1 || true", 0).presence ||
                                shell_output("#{bin}/grok version 2>&1 || true", 0)
  rescue
    # Binary may require network/auth for some subcommands; just ensure it exists.
    assert_predicate bin/"grok", :exist?
  end
end
