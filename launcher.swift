// BocciaTimer.app launcher — a native window around bocciatimer.html.
//
// The timer renders in the system WebKit engine, so the app is its own
// process with its own Cmd-Tab / Dock identity and needs no browser
// installed. It finds bocciatimer.html next to the .app bundle, keeping
// the repo folder relocatable.
//
// Build (from the repo folder — see README):
//   xcrun swiftc -O -parse-as-library launcher.swift \
//     -o BocciaTimer.app/Contents/MacOS/launcher \
//     -target arm64-apple-macos12.3 -framework Cocoa -framework WebKit
//   (build both -target arm64… and x86_64…, then `lipo -create`, for universal)
//
// `launcher --probe [path.html]` loads the page headlessly, prints a JSON
// health report (localStorage, audio, fullscreen, app state) and exits —
// used to verify a build without clicking around.

import Cocoa
import WebKit

final class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate {
    var window: NSWindow!
    var webView: WKWebView!
    let probeMode = CommandLine.arguments.contains("--probe")

    func timerURL() -> URL {
        for arg in CommandLine.arguments.dropFirst() where !arg.hasPrefix("-") {
            return URL(fileURLWithPath: arg)
        }
        return Bundle.main.bundleURL.deletingLastPathComponent()
            .appendingPathComponent("bocciatimer.html")
    }

    func applicationDidFinishLaunching(_ note: Notification) {
        let url = timerURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            if probeMode { print("PROBE: {\"error\":\"missing \(url.path)\"}"); exit(1) }
            let a = NSAlert()
            a.alertStyle = .critical
            a.messageText = "Boccia Timer not found"
            a.informativeText = "bocciatimer.html is not next to BocciaTimer.app. Move the app back into the boccia-timer folder."
            a.runModal()
            exit(1)
        }

        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []   // let the cue sounds fire
        config.preferences.isElementFullscreenEnabled = true   // the F key uses requestFullscreen

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self

        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1280, height: 800),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.title = "BocciaTimer"
        window.minSize = NSSize(width: 800, height: 500)
        window.collectionBehavior.insert(.fullScreenPrimary)
        window.contentView = webView
        if !window.setFrameUsingName("BocciaTimerMain") { window.center() }
        window.setFrameAutosaveName("BocciaTimerMain")

        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())

        if probeMode {
            NSApp.setActivationPolicy(.accessory)
            DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
                print("PROBE: {\"error\":\"timeout\"}"); exit(1)
            }
        } else {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    @objc func doReload(_ sender: Any?) { webView.reload() }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if probeMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { self.runProbe() }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if probeMode { print("PROBE: {\"error\":\"didFail \(error.localizedDescription)\"}"); exit(1) }
    }

    private func runProbe() {
        let js = """
        (function () {
          var out = {};
          try {
            out.persistPrev = localStorage.getItem('__persist');
            localStorage.setItem('__persist', 'yes');
            out.lsWrite = localStorage.getItem('__persist');
          } catch (e) { out.lsError = String(e); }
          out.fullscreenEnabled = document.fullscreenEnabled;
          out.title = document.title;
          out.state = (typeof state === 'undefined') ? 'MISSING' : JSON.stringify(state);
          try { out.audioReadyStates = [beep1min.readyState, beep30s.readyState, alarm.readyState]; }
          catch (e) { out.audioError = String(e); }
          return JSON.stringify(out);
        })()
        """
        webView.evaluateJavaScript(js) { result, error in
            if let error { print("PROBE: {\"error\":\"\(error.localizedDescription)\"}"); exit(1) }
            print("PROBE:", result as? String ?? "null")
            exit(0)
        }
    }
}

@main
enum Main {
    static func buildMenu(appDelegate: AppDelegate) -> NSMenu {
        let main = NSMenu()

        let appItem = NSMenuItem(); main.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About BocciaTimer",
                        action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide BocciaTimer", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Quit BocciaTimer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu

        let editItem = NSMenuItem(); main.addItem(editItem)
        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        edit.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        edit.addItem(.separator())
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = edit

        let viewItem = NSMenuItem(); main.addItem(viewItem)
        let view = NSMenu(title: "View")
        let reload = NSMenuItem(title: "Reload", action: #selector(AppDelegate.doReload(_:)), keyEquivalent: "r")
        reload.target = appDelegate
        view.addItem(reload)
        let fullscreen = NSMenuItem(title: "Enter Full Screen",
                                    action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
        fullscreen.keyEquivalentModifierMask = [.command, .control]
        view.addItem(fullscreen)
        viewItem.submenu = view

        let windowItem = NSMenuItem(); main.addItem(windowItem)
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.zoom(_:)), keyEquivalent: "")
        windowItem.submenu = windowMenu

        return main
    }

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.mainMenu = buildMenu(appDelegate: delegate)
        app.run()
    }
}
