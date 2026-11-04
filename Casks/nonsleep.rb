cask "nonsleep" do
  version "0.3.0"
  sha256 "1390dae2a54d3244708977d93c34400d65d71e3bb672950f25694ec4a596e814"

  url "https://github.com/Tran-Duc-Duy/nonsleep/releases/download/v#{version}/NonSleep-#{version}-macOS.zip"
  name "NonSleep"
  desc "Stays awake with the lid closed while agents work, then sleeps"
  homepage "https://github.com/Tran-Duc-Duy/nonsleep"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :ventura

  app "NonSleep.app"
  binary "#{appdir}/NonSleep.app/Contents/MacOS/nonsleep"

  uninstall_preflight_steps do
    # Restores normal sleep and removes the sudoers rule, the reaper and the CLI link.
    run "NonSleep.app/Contents/MacOS/nonsleep",
        base:         :appdir,
        args:         ["setup", "--remove"],
        must_succeed: false
  end

  zap trash: [
    "~/Library/Application Support/NonSleep",
    "~/Library/LaunchAgents/dev.nonsleep.reaper.plist",
    "~/Library/Preferences/dev.nonsleep.app.plist",
  ]

  caveats <<~EOS
    The app is ad-hoc signed, not notarized. On first launch open it once, then allow it in
    System Settings › Privacy & Security, or run:
      xattr -dr com.apple.quarantine #{appdir}/NonSleep.app

    Then click "Finish setup…" in the NonSleep window (or run `nonsleep setup`) to install the
    sudoers rule that lets NonSleep toggle `pmset -a disablesleep 0|1`.
  EOS
end
