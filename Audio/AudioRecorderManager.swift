import AVFoundation
import Combine
import Foundation

enum AudioRecorderError: LocalizedError {
    case recordingFailed(String)
    case playbackFailed(String)
    case fileNotFound
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .recordingFailed(let msg): return "Recording failed: \(msg)"
        case .playbackFailed(let msg): return "Playback failed: \(msg)"
        case .fileNotFound: return "Audio file not found"
        case .invalidFormat: return "Invalid audio format"
        }
    }
}

struct AudioRecording: Identifiable, Codable {
    let id: String
    let filename: String
    let duration: TimeInterval
    let createdAt: Date
    let fileSize: Int // in bytes

    var durationFormatted: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var fileSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        return formatter.string(fromByteCount: Int64(fileSize))
    }
}

@MainActor
final class AudioRecorderManager: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {

    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var recordings: [AudioRecording] = []
    @Published var lastError: AudioRecorderError?
    @Published var isPlayingId: String?

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private let audioSession = AVAudioSession.sharedInstance()
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let audioDirectory: URL
    private var currentRecordingURL: URL?

    override init() {
        audioDirectory = documentsDirectory.appendingPathComponent("GeoWCSRecordings", isDirectory: true)
        super.init()
        
        do {
            try FileManager.default.createDirectory(at: audioDirectory, withIntermediateDirectories: true)
        } catch {
            print("❌ Failed to create audio directory: \(error)")
        }

        loadRecordings()
    }

    // MARK: - Recording

    func startRecording() {
        do {
            try audioSession.setCategory(.record, mode: .default, options: [])
            try audioSession.setActive(true)

            let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
            let filename = "audio-\(timestamp).m4a"
            let fileURL = audioDirectory.appendingPathComponent(filename)

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()

            currentRecordingURL = fileURL
            isRecording = true
            recordingDuration = 0

            startTimer()
            print("🎙️ Recording started: \(filename)")
        } catch {
            lastError = .recordingFailed(error.localizedDescription)
            print("❌ Failed to start recording: \(error)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        stopTimer()

        if let url = currentRecordingURL {
            do {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let fileSize = fileAttributes[.size] as? Int ?? 0

                let recording = AudioRecording(
                    id: UUID().uuidString,
                    filename: url.lastPathComponent,
                    duration: recordingDuration,
                    createdAt: Date(),
                    fileSize: fileSize
                )

                recordings.insert(recording, at: 0)
                persistRecordings()
                print("✅ Recording saved: \(recording.filename)")
            } catch {
                lastError = .recordingFailed("Failed to save recording: \(error)")
            }
        }

        currentRecordingURL = nil
        recordingDuration = 0
    }

    // MARK: - Playback

    func play(recording: AudioRecording) {
        let fileURL = audioDirectory.appendingPathComponent(recording.filename)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            lastError = .fileNotFound
            return
        }

        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.delegate = self
            audioPlayer?.play()

            isPlayingId = recording.id
            print("▶️ Playing: \(recording.filename)")
        } catch {
            lastError = .playbackFailed(error.localizedDescription)
        }
    }

    func stopPlayback() {
        audioPlayer?.stop()
        isPlayingId = nil
    }

    // MARK: - Management

    func deleteRecording(_ recording: AudioRecording) {
        let fileURL = audioDirectory.appendingPathComponent(recording.filename)

        do {
            try FileManager.default.removeItem(at: fileURL)
            recordings.removeAll { $0.id == recording.id }
            persistRecordings()
            print("🗑️ Deleted: \(recording.filename)")
        } catch {
            lastError = .recordingFailed("Failed to delete: \(error)")
        }
    }

    func shareRecording(_ recording: AudioRecording) -> URL {
        audioDirectory.appendingPathComponent(recording.filename)
    }

    // MARK: - Private

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.recordingDuration += 0.1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func loadRecordings() {
        guard let data = UserDefaults.standard.data(forKey: "audioRecordings") else {
            recordings = []
            return
        }

        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode([AudioRecording].self, from: data) {
            // Filter out recordings whose files no longer exist
            recordings = decoded.filter { recording in
                FileManager.default.fileExists(atPath: audioDirectory.appendingPathComponent(recording.filename).path)
            }
            if recordings.count < decoded.count {
                persistRecordings()
            }
        }
    }

    private func persistRecordings() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(recordings) {
            UserDefaults.standard.set(encoded, forKey: "audioRecordings")
        }
    }

    // MARK: - Delegates

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("⚠️ Recording finished with error")
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlayingId = nil
        }
    }
}
