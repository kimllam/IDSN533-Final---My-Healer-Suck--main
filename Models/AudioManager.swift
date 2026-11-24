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

    // Default slider setting of 70% plays at 14% player volume.
    private let musicGain: Float = 0.2

    private var applicationIsActive = false
    private var isInterrupted = false
    private var currentMusicName: String?
    private var currentMusicExtension: String?

    private var musicPlayer: AVAudioPlayer?
    private var ambientPlayer: AVAudioPlayer?
    private var effectsPlayers: [AVAudioPlayer] = []
    private let maxSimultaneousEffects = 12

    private var musicEnabled = true
    private var ambientEnabled = true
    private var sfxEnabled = true

    private var musicVolume: Float = 0.7
    private var ambientVolume: Float = 0.5
    private var sfxVolume: Float = 0.8

    private override init() {
        super.init()
        loadSavedSettings()

        do {
            // Respect Silent Mode and allow other audio to continue.
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default
            )
        } catch {
            print(
                "Audio session configuration error: \(error.localizedDescription)"
            )
        }

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

        if active {
            loadSavedSettings()

            if musicPlayer == nil {
                playMusic(named: "kiravale-medieval-music-593694")
            } else {
                updatePlayers()
            }
        } else {
            musicPlayer?.pause()
            ambientPlayer?.pause()
            stopEffects()
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

    // MARK: - Saved Preferences

    private func loadSavedSettings() {
        let settings = UserDefaults.standard

        musicEnabled = settings.object(
            forKey: "musicEnabled"
        ) as? Bool ?? true

        ambientEnabled = settings.object(
            forKey: "ambientEnabled"
        ) as? Bool ?? true

        sfxEnabled = settings.object(
            forKey: "sfxEnabled"
        ) as? Bool ?? true

        musicVolume = Float(
            settings.object(
                forKey: "musicVolume"
            ) as? Double ?? 0.7
        )

        ambientVolume = Float(
            settings.object(
                forKey: "ambientVolume"
            ) as? Double ?? 0.5
        )

        sfxVolume = Float(
            settings.object(
                forKey: "sfxVolume"
            ) as? Double ?? 0.8
        )
    }

    // MARK: - Update Settings

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

        self.musicVolume = Float(
            min(max(musicVolume, 0), 1)
        )

        self.ambientVolume = Float(
            min(max(ambientVolume, 0), 1)
        )

        self.sfxVolume = Float(
            min(max(sfxVolume, 0), 1)
        )

        updatePlayers()
    }

    // MARK: - Background Music

    func playMusic(
        named name: String,
        extension fileExtension: String = "mp3"
    ) {
        if musicPlayer == nil
            || currentMusicName != name
            || currentMusicExtension != fileExtension {

            musicPlayer = makePlayer(
                named: name,
                fileExtension: fileExtension,
                loop: true
            )

            currentMusicName = name
            currentMusicExtension = fileExtension
        }

        updatePlayers()
    }

    // MARK: - Ambient Sounds

    func playAmbient(
        named name: String,
        extension fileExtension: String = "wav"
    ) {
        ambientPlayer = makePlayer(
            named: name,
            fileExtension: fileExtension,
            loop: true
        )

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

        // Remove sounds that finished playing so they do not accumulate.
        effectsPlayers.removeAll { !$0.isPlaying }

        // Limit overlapping sounds to prevent excessive volume and memory use.
        if effectsPlayers.count >= maxSimultaneousEffects {
            effectsPlayers[0].stop()
            effectsPlayers.removeFirst()
        }

        guard let player = makePlayer(
            named: name,
            fileExtension: fileExtension,
            loop: false
        ) else {
            return
        }

        player.volume = sfxVolume
        effectsPlayers.append(player)
        player.play()
    }

    // MARK: - Player Factory

    private func makePlayer(
        named name: String,
        fileExtension: String,
        loop: Bool
    ) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(
            forResource: name,
            withExtension: fileExtension
        ) else {
            print(
                "Audio file not found: \(name).\(fileExtension)"
            )
            return nil
        }

        do {
            let player = try AVAudioPlayer(
                contentsOf: url
            )

            player.numberOfLoops = loop ? -1 : 0
            player.prepareToPlay()

            return player
        } catch {
            print(
                "Audio playback error: \(error.localizedDescription)"
            )
            return nil
        }
    }

    // MARK: - Apply Volumes

    private func updatePlayers() {
        musicPlayer?.volume = musicVolume * musicGain
        ambientPlayer?.volume = ambientVolume
        for player in effectsPlayers {
            player.volume = sfxEnabled ? sfxVolume : 0
        }

        guard applicationIsActive, !isInterrupted else {
            return
        }

        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(
                "Audio session activation error: \(error.localizedDescription)"
            )
            return
        }

        if musicEnabled {
            if musicPlayer?.isPlaying == false {
                musicPlayer?.play()
            }
        } else {
            musicPlayer?.pause()
        }

        if ambientEnabled {
            if ambientPlayer?.isPlaying == false {
                ambientPlayer?.play()
            }
        } else {
            ambientPlayer?.pause()
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
    }

    func stopAmbient() {
        ambientPlayer?.stop()
        ambientPlayer = nil
    }

    func stopAll() {
        stopMusic()
        stopAmbient()
        stopEffects()
    }
}

// MARK: - Haptic Feedback
// Keep this class in AudioManager.swift.

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

