//
//  AudioManager.swift
//  IDSN533 MyHealerSuck
//
//  Created by Jingyi on 11/15/26.
//

import Foundation
import AVFoundation
import UIKit

@MainActor
final class AudioManager: NSObject {

    static let shared = AudioManager()

    // Keeps background music quiet.
    // A 70% music slider setting produces 14% player volume.
    private let musicGain: Float = 0.2

    private let backgroundMusicName =
        "kiravale-medieval-music-593694"

    private var applicationIsActive = false
    private var isInterrupted = false

    private var musicPlayer: AVAudioPlayer?
    private var ambientPlayer: AVAudioPlayer?
    private var effectsPlayers: [AVAudioPlayer] = []

    private var currentMusicURL: URL?
    private var currentAmbientURL: URL?

    private let maxSimultaneousEffects = 12

    private var musicEnabled = true
    private var ambientEnabled = true
    private var sfxEnabled = true

    private var musicVolume: Float = 0.7
    private var ambientVolume: Float = 0.5
    private var sfxVolume: Float = 0.8

    private let supportedExtensions = [
        "wav", "mp3", "m4a", "aac",
        "caf", "aif", "aiff", "mp4"
    ]

    private var reportedMissingFiles = Set<String>()

    // Finds audio in the bundle root and nested folders,
    // including Sounds or a preserved project folder.
    private lazy var bundledAudioURLs: [URL] = {
        guard let resourceURL = Bundle.main.resourceURL,
              let enumerator = FileManager.default.enumerator(
                at: resourceURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
              ) else {
            return []
        }

        var urls: [URL] = []

        for case let url as URL in enumerator {
            guard supportedExtensions.contains(
                url.pathExtension.lowercased()
            ) else {
                continue
            }

            let values = try? url.resourceValues(
                forKeys: [.isRegularFileKey]
            )

            if values?.isRegularFile == true {
                urls.append(url)
            }
        }

        return urls.sorted { $0.path < $1.path }
    }()

    private override init() {
        super.init()

        loadSavedSettings()

        applicationIsActive =
            UIApplication.shared.applicationState == .active

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    // MARK: - App Lifecycle

    func setApplicationActive(_ active: Bool) {
        applicationIsActive = active

        guard active else {
            musicPlayer?.pause()
            ambientPlayer?.pause()
            stopEffects()
            return
        }

        loadSavedSettings()

        if musicPlayer == nil {
            playMusic(named: backgroundMusicName)
        } else {
            updatePlayers()
        }
    }

    // MARK: - Audio Session

    private func activateAudioSession() -> Bool {
        guard applicationIsActive, !isInterrupted else {
            return false
        }

        do {
            let session = AVAudioSession.sharedInstance()

            // Play even when the device is in Silent Mode.
            // Other apps' audio can continue playing.
            try session.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )

            try session.setActive(true)
            return true
        } catch {
            print(
                "[Audio] Session error: \(error.localizedDescription)"
            )
            return false
        }
    }

    @objc private func handleInterruption(
        _ notification: Notification
    ) {
        guard
            let rawType = notification.userInfo?[
                AVAudioSessionInterruptionTypeKey
            ] as? UInt,
            let type = AVAudioSession.InterruptionType(
                rawValue: rawType
            )
        else {
            return
        }

        switch type {
        case .began:
            isInterrupted = true
            musicPlayer?.pause()
            ambientPlayer?.pause()
            stopEffects()

        case .ended:
            isInterrupted = false

            let rawOptions = notification.userInfo?[
                AVAudioSessionInterruptionOptionKey
            ] as? UInt ?? 0

            let options = AVAudioSession.InterruptionOptions(
                rawValue: rawOptions
            )

            if options.contains(.shouldResume) {
                updatePlayers()
            }

        @unknown default:
            break
        }
    }

    // MARK: - Saved Settings

    private func loadSavedSettings() {
        let settings = UserDefaults.standard

        musicEnabled =
            settings.object(forKey: "musicEnabled") as? Bool
            ?? true

        ambientEnabled =
            settings.object(forKey: "ambientEnabled") as? Bool
            ?? true

        sfxEnabled =
            settings.object(forKey: "sfxEnabled") as? Bool
            ?? true

        musicVolume = clampedVolume(
            settings.object(forKey: "musicVolume") as? Double
            ?? 0.7
        )

        ambientVolume = clampedVolume(
            settings.object(forKey: "ambientVolume") as? Double
            ?? 0.5
        )

        sfxVolume = clampedVolume(
            settings.object(forKey: "sfxVolume") as? Double
            ?? 0.8
        )
    }

    private func clampedVolume(_ value: Double) -> Float {
        guard value.isFinite else { return 0 }
        return Float(min(max(value, 0), 1))
    }

    func applySettings(
        musicEnabled: Bool,
        ambientEnabled: Bool,
        sfxEnabled: Bool,
        musicVolume: Double,
        ambientVolume: Double,
        sfxVolume: Double
    ) {
        self.musicEnabled = musicEnabled
        self.ambientEnabled = ambientEnabled
        self.sfxEnabled = sfxEnabled

        self.musicVolume = clampedVolume(musicVolume)
        self.ambientVolume = clampedVolume(ambientVolume)
        self.sfxVolume = clampedVolume(sfxVolume)

        if !sfxEnabled {
            stopEffects()
        }

        updatePlayers()
    }

    // MARK: - Background Music

    func playMusic(
        named name: String,
        extension fileExtension: String = "mp3"
    ) {
        guard let url = findAudioURL(
            named: name,
            preferredExtension: fileExtension
        ) else {
            return
        }

        if musicPlayer == nil || currentMusicURL != url {
            guard let player = makePlayer(
                url: url,
                loop: true
            ) else {
                return
            }

            musicPlayer?.stop()
            musicPlayer = player
            currentMusicURL = url
        }

        updatePlayers()
    }

    // MARK: - Ambient Sounds

    func playAmbient(
        named name: String,
        extension fileExtension: String = "wav"
    ) {
        guard let url = findAudioURL(
            named: name,
            preferredExtension: fileExtension
        ) else {
            return
        }

        if ambientPlayer == nil || currentAmbientURL != url {
            guard let player = makePlayer(
                url: url,
                loop: true
            ) else {
                return
            }

            ambientPlayer?.stop()
            ambientPlayer = player
            currentAmbientURL = url
        }

        updatePlayers()
    }

    // MARK: - Sound Effects

    func playEffect(
        named name: String,
        extension fileExtension: String = "wav"
    ) {
        guard
            sfxEnabled,
            applicationIsActive,
            !isInterrupted
        else {
            return
        }

        guard let url = findAudioURL(
            named: name,
            preferredExtension: fileExtension
        ) else {
            return
        }

        guard activateAudioSession() else {
            return
        }

        effectsPlayers.removeAll { !$0.isPlaying }

        if effectsPlayers.count >= maxSimultaneousEffects {
            effectsPlayers.removeFirst().stop()
        }

        guard let player = makePlayer(
            url: url,
            loop: false
        ) else {
            return
        }

        player.volume = sfxVolume
        effectsPlayers.append(player)

        if !player.play() {
            print(
                "[Audio] Could not play effect: \(url.lastPathComponent)"
            )

            effectsPlayers.removeAll { $0 === player }
        }
    }

    // MARK: - Find Audio Files

    private func findAudioURL(
        named name: String,
        preferredExtension: String
    ) -> URL? {
        let requestedName = name as NSString
        let includedExtension = requestedName.pathExtension

        let stem: String

        if includedExtension.isEmpty {
            stem = name
        } else {
            stem = requestedName.deletingPathExtension
        }

        let firstExtension = includedExtension.isEmpty
            ? preferredExtension
            : includedExtension

        var extensions: [String] = []

        for item in [firstExtension] + supportedExtensions {
            let normalized = item
                .trimmingCharacters(in: CharacterSet(charactersIn: "."))
                .lowercased()

            if !normalized.isEmpty,
               !extensions.contains(normalized) {
                extensions.append(normalized)
            }
        }

        // Xcode groups may place files in the bundle root.
        // Folder references may preserve the Sounds directory.
        for ext in extensions {
            if let url = Bundle.main.url(
                forResource: stem,
                withExtension: ext
            ) {
                return url
            }

            if let url = Bundle.main.url(
                forResource: stem,
                withExtension: ext,
                subdirectory: "Sounds"
            ) {
                return url
            }
        }

        // Search preserved nested folders as well.
        // Match filenames without requiring exact capitalization.
        let baseName = (stem as NSString).lastPathComponent

        for ext in extensions {
            let expectedFilename = "\(baseName).\(ext)"

            if let url = bundledAudioURLs.first(where: {
                $0.lastPathComponent.caseInsensitiveCompare(
                    expectedFilename
                ) == .orderedSame
            }) {
                return url
            }
        }

        reportMissingFile(name)
        return nil
    }

    private func reportMissingFile(_ name: String) {
        guard reportedMissingFiles.insert(name).inserted else {
            return
        }

        print("[Audio] Missing bundled audio: \(name)")

        print(
            "[Audio] Check Target Membership and Copy Bundle Resources."
        )

        let filenames = bundledAudioURLs.map {
            $0.lastPathComponent
        }

        if filenames.isEmpty {
            print("[Audio] No audio files found in the built app.")
        } else {
            print(
                "[Audio] Available audio files: "
                + filenames.joined(separator: ", ")
            )
        }
    }

    // MARK: - Create Players

    private func makePlayer(
        url: URL,
        loop: Bool
    ) -> AVAudioPlayer? {
        do {
            let player = try AVAudioPlayer(contentsOf: url)

            // -1 repeats continuously.
            player.numberOfLoops = loop ? -1 : 0
            player.prepareToPlay()

            return player
        } catch {
            print(
                "[Audio] Cannot load \(url.lastPathComponent): "
                + error.localizedDescription
            )

            return nil
        }
    }

    // MARK: - Apply Playback Settings

    private func updatePlayers() {
        musicPlayer?.volume = musicVolume * musicGain
        ambientPlayer?.volume = ambientVolume

        for player in effectsPlayers {
            player.volume = sfxEnabled ? sfxVolume : 0
        }

        // Apply mute/pause even if the app is inactive.
        if !musicEnabled {
            musicPlayer?.pause()
        }

        if !ambientEnabled {
            ambientPlayer?.pause()
        }

        guard activateAudioSession() else {
            return
        }

        if musicEnabled,
           let player = musicPlayer,
           !player.isPlaying {

            if !player.play() {
                print("[Audio] Background music failed to start.")
            }
        }

        if ambientEnabled,
           let player = ambientPlayer,
           !player.isPlaying {

            if !player.play() {
                print("[Audio] Ambient audio failed to start.")
            }
        }
    }

    // MARK: - Stop Audio

    private func stopEffects() {
        effectsPlayers.forEach { $0.stop() }
        effectsPlayers.removeAll()
    }

    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
        currentMusicURL = nil
    }

    func stopAmbient() {
        ambientPlayer?.stop()
        ambientPlayer = nil
        currentAmbientURL = nil
    }

    func stopAll() {
        stopMusic()
        stopAmbient()
        stopEffects()
    }
}

// MARK: - Haptic Feedback

@MainActor
final class HapticsManager {

    static let shared = HapticsManager()

    private let selection = UISelectionFeedbackGenerator()

    private let impact = UIImpactFeedbackGenerator(
        style: .medium
    )

    private let gentleImpact = UIImpactFeedbackGenerator(
        style: .light
    )

    private let notification = UINotificationFeedbackGenerator()

    private var enabled: Bool {
        let hapticsEnabled = UserDefaults.standard.object(
            forKey: "hapticsEnabled"
        ) as? Bool ?? true

        return hapticsEnabled
            && UIApplication.shared.applicationState == .active
    }

    private init() {}

    func cardPlaced() {
        guard enabled else { return }

        selection.selectionChanged()
        selection.prepare()
    }

    func damage() {
        guard enabled else { return }

        impact.impactOccurred()
        impact.prepare()
    }

    func heal() {
        guard enabled else { return }

        gentleImpact.impactOccurred(intensity: 0.6)
        gentleImpact.prepare()
    }

    func gameOver(won: Bool) {
        guard enabled else { return }

        notification.notificationOccurred(
            won ? .success : .error
        )

        notification.prepare()
    }
}
