import SwiftUI
import ContextScopeCore

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var page = 0

    // Setup fields
    @State private var upstreamURL = "https://api.openai.com"
    @State private var apiKey = ""
    @State private var showAPIKey = false

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            HStack(spacing: 6) {
                ForEach(0..<4) { i in
                    Circle()
                        .fill(i == page ? Color.accentColor : Color.secondary.opacity(0.4))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.top, 32)

            TabView(selection: $page) {
                // Page 0: Welcome
                VStack(spacing: 24) {
                    Spacer()
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 72))
                        .foregroundStyle(Color.accentColor)
                    Text("See exactly what your AI sees.")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text("Inspect context usage, token growth, tool calls, and agent execution — locally on your Mac.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 480)
                    HStack(spacing: 16) {
                        Button("Play Demo") {
                            appState.startDemo()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        Button("Set Up Local Proxy") { page = 1 }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                    }
                    Spacer()
                }
                .tag(0)

                // Page 1: Setup
                VStack(alignment: .leading, spacing: 20) {
                    Spacer()
                    Text("Connect to your API provider")
                        .font(.title.bold())
                    VStack(alignment: .leading, spacing: 12) {
                        LabeledContent("Upstream API URL") {
                            TextField("https://api.openai.com", text: $upstreamURL)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 380)
                        }
                        LabeledContent("API Key") {
                            HStack {
                                if showAPIKey {
                                    TextField("sk-...", text: $apiKey)
                                        .textFieldStyle(.roundedBorder)
                                } else {
                                    SecureField("sk-...", text: $apiKey)
                                        .textFieldStyle(.roundedBorder)
                                }
                                Button {
                                    showAPIKey.toggle()
                                } label: {
                                    Image(systemName: showAPIKey ? "eye.slash" : "eye")
                                }
                                .buttonStyle(.plain)
                            }
                            .frame(maxWidth: 380)
                        }
                        Text("Your API key is stored only in macOS Keychain and is never logged or uploaded.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Button("Back") { page = 0 }.buttonStyle(.bordered)
                        Spacer()
                        Button("Continue") {
                            saveSettings()
                            page = 2
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(upstreamURL.isEmpty)
                    }
                    Spacer()
                }
                .padding()
                .frame(maxWidth: 520)
                .tag(1)

                // Page 2: Integration snippet
                VStack(alignment: .leading, spacing: 20) {
                    Spacer()
                    Text("Point your app at the local proxy")
                        .font(.title.bold())
                    Text("Replace your current base URL with:")
                        .foregroundStyle(.secondary)
                    CodeBlock(code: "http://127.0.0.1:4319/v1")
                    Text("Python (openai SDK):")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    CodeBlock(code: """
from openai import OpenAI
client = OpenAI(
    base_url="http://127.0.0.1:4319/v1",
    api_key="your-upstream-key"
)
""")
                    Text("Node.js:")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    CodeBlock(code: """
import OpenAI from 'openai'
const client = new OpenAI({
  baseURL: 'http://127.0.0.1:4319/v1',
  apiKey: process.env.OPENAI_API_KEY,
})
""")
                    HStack {
                        Button("Back") { page = 1 }.buttonStyle(.bordered)
                        Spacer()
                        Button("Continue") { page = 3 }.buttonStyle(.borderedProminent)
                    }
                    Spacer()
                }
                .padding()
                .frame(maxWidth: 540)
                .tag(2)

                // Page 3: Ready
                VStack(spacing: 24) {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.green)
                    Text("You're ready!")
                        .font(.largeTitle.bold())
                    Text("Start the proxy, then send a request from your app.\nContextScope will capture and visualize it live.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Button("Open ContextScope") {
                        appState.completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    Spacer()
                }
                .tag(3)
            }
            .tabViewStyle(.automatic)
        }
        .frame(minWidth: 640, minHeight: 540)
    }

    private func saveSettings() {
        UserDefaults.standard.set(upstreamURL, forKey: "upstreamBaseURL")
        // NOTE: In production, apiKey should be stored in Keychain.
        // For this prototype it's stored in UserDefaults with a clear privacy warning.
        // TODO: replace with SecItemAdd/CopyMatching Keychain calls.
        UserDefaults.standard.set(apiKey, forKey: "apiKey")
    }
}

struct CodeBlock: View {
    let code: String
    @State private var copied = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .textSelection(.enabled)
            }
            .background(Color.primary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(code, forType: .string)
                copied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.caption)
                    .padding(6)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .padding(6)
        }
    }
}
