//
//  AudioManager.swift
//  IDSN533 MyHealerSuck
//
//  Created by Jingyi on 11/15/26.
//


import Foundation
import AVFoundation

@MainActor
final class AudioManager {

    static let shared = AudioManager()

    private var musicPlayer: AVAudioPlayer?
    private var ambientPlayer: AVAudioPlayer?
    private var effectsPlayer: AVAudioPlayer?

    private var musicEnabled = true
    private var ambientEnabled = true
    private var sfxEnabled = true

    private var musicVolume: Float = 0.7
    private var ambientVolume: Float = 0.5
    private var sfxVolume: Float = 0.8

    private init() {
        loadSavedSettings()
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
        musicPlayer = makePlayer(
            named: name,
            fileExtension: fileExtension,
            loop: true
        )

        musicPlayer?.volume =
            musicEnabled ? musicVolume : 0

        musicPlayer?.play()
    }

    // MARK: - Ambient Sounds

    func playAmbient(
        named name: String,
        extension fileExtension: String = "mp3"
    ) {
        ambientPlayer = makePlayer(
            named: name,
            fileExtension: fileExtension,
            loop: true
        )

        ambientPlayer?.volume =
            ambientEnabled ? ambientVolume : 0

        ambientPlayer?.play()
    }

    // MARK: - Sound Effects

    func playEffect(
        named name: String,
        extension fileExtension: String = "wav"
    ) {
        guard sfxEnabled else {
            return
        }

        effectsPlayer = makePlayer(
            named: name,
            fileExtension: fileExtension,
            loop: false
        )

        effectsPlayer?.volume = sfxVolume
        effectsPlayer?.play()
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
        musicPlayer?.volume =
            musicEnabled ? musicVolume : 0

        ambientPlayer?.volume =
            ambientEnabled ? ambientVolume : 0

        effectsPlayer?.volume =
            sfxEnabled ? sfxVolume : 0
    }

    // MARK: - Stop Audio

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
        effectsPlayer?.stop()
        effectsPlayer = nil
    }
}
