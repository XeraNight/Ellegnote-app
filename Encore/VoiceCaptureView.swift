import SwiftUI

/// Voice dictation on Home. Owns the speech recognizer so the rapidly changing audio level only
/// redraws this small view and not the whole Home screen.
struct VoiceCaptureView: View {
    /// Called with the final transcript when the user taps "Uložiť prepis".
    let onSave: (String) -> Void

    @StateObject private var speech = SpeechRecognizerHelper()
    @State private var text = ""

    private var hasText: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            waveform

            if hasText {
                Text(text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .lineLimit(5)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.10), lineWidth: 1))
            } else {
                Text(speech.isRecording
                     ? "Hovorte zreteľne o choreografii alebo technike..."
                     : "Stlačte mikrofón a začnite diktovať tréningovú poznámku")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
            }

            Spacer()

            HStack(spacing: 20) {
                micButton

                if hasText {
                    Button(action: save) {
                        Text("Uložiť prepis")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.obsidian900)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 11)
                            .background(
                                LinearGradient(colors: [Color.gold500, Color.gold400], startPoint: .leading, endPoint: .trailing),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.pressable)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.bottom, 22)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: hasText)
        }
        .onChange(of: speech.transcript) { _, newTranscript in
            if !newTranscript.isEmpty { text = newTranscript }
        }
        .onAppear { speech.requestPermissions() }
        .onDisappear { _ = speech.stopTranscribing() }
        .sensoryFeedback(.impact(flexibility: .rigid), trigger: speech.isRecording)
    }

    private var waveform: some View {
        HStack(spacing: 4) {
            ForEach(0..<20, id: \.self) { index in
                let waveFactor = sin(Double(index) / 20.0 * .pi)
                let barHeight: CGFloat = speech.isRecording
                    ? max(6, 10 + speech.audioLevel * 50 * CGFloat(waveFactor))
                    : 6
                Capsule()
                    .fill(
                        speech.isRecording
                        ? LinearGradient(colors: [Color.latinCrimson, Color.gold400], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Color.white.opacity(0.18), Color.white.opacity(0.08)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 4, height: barHeight)
                    .animation(.easeOut(duration: 0.08), value: barHeight)
            }
        }
        .frame(height: 70)
    }

    private var micButton: some View {
        Button(action: toggle) {
            ZStack {
                Circle()
                    .fill(speech.isRecording ? Color.latinCrimson.opacity(0.20) : Color.gold500.opacity(0.15))
                    .frame(width: 76, height: 76)
                    .scaleEffect(speech.isRecording ? 1.0 + min(speech.audioLevel, 1.0) * 0.35 : 1.0)
                    .animation(.easeOut(duration: 0.1), value: speech.audioLevel)

                Circle()
                    .fill(speech.isRecording ? Color.latinCrimson : Color.gold500)
                    .frame(width: 60, height: 60)

                Image(systemName: speech.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(speech.isRecording ? .white : Color.obsidian900)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .buttonStyle(.pressable(scale: 0.9))
    }

    private func toggle() {
        if speech.isRecording {
            let captured = speech.stopTranscribing()
            if !captured.isEmpty { text = captured }
        } else {
            speech.transcript = ""
            speech.startTranscribing()
        }
    }

    private func save() {
        if speech.isRecording {
            let captured = speech.stopTranscribing()
            if !captured.isEmpty { text = captured }
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSave(trimmed)
        text = ""
        speech.transcript = ""
    }
}
