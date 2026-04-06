import SwiftUI
import AVFoundation

struct AudioRecorderView: View {
    @StateObject private var recorder = AudioRecorderManager()
    @State private var recordingToShare: AudioRecording?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Recording section
                recordingSection

                Divider()

                // Recordings list
                if recorder.recordings.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "waveform")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No Recordings Yet")
                            .font(.headline)
                        Text("Start recording to capture audio")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else {
                    List {
                        Section("Saved Recordings") {
                            ForEach(recorder.recordings) { recording in
                                recordingRow(recording)
                            }
                            .onDelete { indices in
                                indices.forEach { i in
                                    recorder.deleteRecording(recorder.recordings[i])
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Audio Recorder")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: .constant(recorder.lastError != nil), presenting: recorder.lastError) { _ in
                Button("OK") { recorder.lastError = nil }
            } message: { error in
                Text(error.errorDescription ?? "Unknown error")
            }
            .sheet(item: $recordingToShare) { recording in
                ShareSheet(items: [recorder.shareRecording(recording)])
            }
        }
    }

    // MARK: - Recording Section

    private var recordingSection: some View {
        VStack(spacing: 16) {
            // Waveform visualization during recording
            if recorder.isRecording {
                waveformVisualizer
                    .frame(height: 60)
                    .padding(.horizontal)
            }

            // Duration display
            HStack {
                Text(recorder.isRecording ? "Recording..." : "Ready")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(recorder.isRecording ? .red : .secondary)

                Spacer()

                Text(formatDuration(recorder.recordingDuration))
                    .font(.title3.monospacedDigit().bold())
                    .foregroundStyle(recorder.isRecording ? .red : .primary)
            }
            .padding(.horizontal)

            // Record button
            HStack(spacing: 12) {
                Button {
                    if recorder.isRecording {
                        recorder.stopRecording()
                    } else {
                        recorder.startRecording()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: recorder.isRecording ? "stop.circle.fill" : "record.circle.fill")
                            .font(.system(size: 20))
                        Text(recorder.isRecording ? "Stop Recording" : "Start Recording")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(recorder.isRecording ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)

                if recorder.recordingDuration > 0 && !recorder.isRecording {
                    Button {
                        recorder.startRecording()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 48, height: 48)
                            .background(Color(.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Waveform

    private var waveformVisualizer: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<20, id: \.self) { _ in
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.red)
                        .frame(height: CGFloat.random(in: 10...50))
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .animation(.easeInOut(duration: 0.2), value: recorder.recordingDuration)
    }

    // MARK: - Recording Row

    @ViewBuilder
    private func recordingRow(_ recording: AudioRecording) -> some View {
        HStack(spacing: 12) {
            // Play button
            Button {
                if recorder.isPlayingId == recording.id {
                    recorder.stopPlayback()
                } else {
                    recorder.play(recording: recording)
                }
            } label: {
                Image(systemName: recorder.isPlayingId == recording.id ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(recorder.isPlayingId == recording.id ? .blue : .secondary)
            }
            .buttonStyle(.plain)

            // Recording info
            VStack(alignment: .leading, spacing: 4) {
                Text(recording.filename)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label(recording.durationFormatted, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label(recording.fileSizeFormatted, systemImage: "doc.badge.doc")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Share button
            Menu {
                Button {
                    recordingToShare = recording
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                Button(role: .destructive) {
                    recorder.deleteRecording(recording)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 60)
        .contentShape(Rectangle())
    }

    // MARK: - Helpers

    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    AudioRecorderView()
}
