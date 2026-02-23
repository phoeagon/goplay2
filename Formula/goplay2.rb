class Goplay2 < Formula
  desc "AirPlay 2 Speaker implementation in Go"
  homepage "https://github.com/phoeagon/goplay2"
  url "https://github.com/phoeagon/goplay2/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "e0c6996de90807452b9413f1d8149ae86bd8c45bf449ef4c342e59b5ace940bd"
  license "Apache-2.0"

  # Only macOS (Apple Silicon / arm64) is officially supported via this formula.
  # Linux and amd64 builds are possible but require different audio back-ends.
  depends_on "go" => :build
  depends_on "pkg-config" => :build
  depends_on "fdk-aac"
  depends_on "portaudio"
  depends_on "pulseaudio"
  depends_on :macos

  def install
    # Resolve any missing/updated indirect dependencies before building.
    system "go", "get", "-u", "golang.org/x/net"
    system "go", "get", "-u", "golang.org/x/sys"
    system "go", "mod", "tidy"

    # Build the binary and install it into the Homebrew prefix.
    system "go", "build", *std_go_args(ldflags: "-s -w")

    # Write man page inline (content is embedded in the formula so it works
    # regardless of which tarball version is being built).
    (buildpath/"goplay2.1").write <<~EOS
      .\\" Man page for goplay2
      .TH GOPLAY2 1 "February 2026" "goplay2 1.0.1" "User Commands"
      .SH NAME
      goplay2 \\- AirPlay 2 speaker receiver
      .SH SYNOPSIS
      .B goplay2
      .RB [\\| \\-n
      .IR name \\|]
      .RB [\\| \\-i
      .IR interface \\|]
      .RB [\\| \\-delay
      .IR ms \\|]
      .RB [\\| \\-sink
      .IR pulse\\-sink \\|]
      .SH DESCRIPTION
      .B goplay2
      is a working AirPlay 2 speaker implementation written in Go.
      It exposes an AirPlay 2 receiver on the local network, supports AAC audio
      at 44100 Hz (Apple Music), HomeKit pairing, PTP synchronisation, and
      multi-room audio via HomePod mini.
      .PP
      On macOS the system built-in AirPlay Receiver must be disabled before
      running goplay2 (System Settings \\(-> General \\(-> AirDrop & Handoff \\(->
      AirPlay Receiver off).
      .SH OPTIONS
      .TP
      .BI \\-n " name"
      Bonjour / AirPlay service name advertised on the network.
      Default: \\fBgoplay\\fR.
      .TP
      .BI \\-i " interface"
      Network interface to listen on (e.g.\\& \\fBen0\\fR, \\fBeth0\\fR).
      Default: \\fBeth0\\fR.
      .TP
      .BI \\-delay " ms"
      Subtract this many milliseconds from the local audio clock to compensate
      for hardware latency. Default: \\fB0\\fR.
      .TP
      .BI \\-sink " pulse\\-sink"
      PulseAudio output sink name. Linux only; ignored on macOS.
      .SH EXAMPLES
      .PP
      Start on macOS using the Wi-Fi interface:
      .PP
      .RS 4
      .nf
      pulseaudio --start
      goplay2 -i en0 -n "Living Room"
      .fi
      .RE
      .PP
      Start on Linux with a specific PulseAudio sink and a 60 ms delay:
      .PP
      .RS 4
      .nf
      goplay2 -i eth0 -n Speaker -sink alsa_output -delay 60
      .fi
      .RE
      .SH NOTES
      On Linux, grant the binary the required capability to bind PTP ports:
      .PP
      .RS 4
      .nf
      sudo setcap 'cap_net_bind_service=+ep' ./goplay2
      .fi
      .RE
      .SH SEE ALSO
      .BR pulseaudio (1)
      .SH AUTHORS
      AlbanSeurat and contributors.
      See \\fIhttps://github.com/phoeagon/goplay2\\fR for the full author list.
      .SH LICENSE
      Apache License 2.0.
    EOS
    man1.install Utils::Gzip.compress(buildpath/"goplay2.1")
  end

  def caveats
    <<~EOS
      goplay2 requires PulseAudio to be running.
      On macOS you can start it with:
        pulseaudio --start

      On newer macOS versions you must disable the built-in AirPlay Receiver
      (System Settings → General → AirDrop & Handoff → AirPlay Receiver) before
      running goplay2.

      Example usage:
        goplay2 -i en0 -n MyAirPlay
    EOS
  end

  test do
    # Just verify the binary runs and prints its usage/help.
    assert_match "goplay2", shell_output("#{bin}/goplay2 --help 2>&1", 2)
  end
end
