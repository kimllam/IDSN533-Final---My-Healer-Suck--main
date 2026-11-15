//
//  SettingsView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Jingyi on 11/15/26.
//


import SwiftUI

struct SettingsView: View {

    // MARK: - Saved Audio Preferences

    @AppStorage("musicEnabled")
    private var musicEnabled = true

    @AppStorage("ambientEnabled")
    private var ambientEnabled = true

    @AppStorage("sfxEnabled")
    private var sfxEnabled = true

    @AppStorage("musicVolume")
    private var musicVolume = 0.7

    @AppStorage("ambientVolume")
    private var ambientVolume = 0.5

    @AppStorage("sfxVolume")
    private var sfxVolume = 0.8

    @AppStorage("hapticsEnabled")
    private var hapticsEnabled = true

    @Environment(\.dismiss)
    private var dismiss

    @State private var showTutorial = false

    // MARK: - Existing Game Colors

    private let background = Color(
        red: 252 / 255,
        green: 220 / 255,
        blue: 187 / 255
    )

    private let paper = Color(
        red: 255 / 255,
        green: 243 / 255,
        blue: 228 / 255
    )

    private let brown = Color(
        red: 89 / 255,
        green: 59 / 255,
        blue: 46 / 255
    )

    private let outline = Color(
        red: 190 / 255,
        green: 151 / 255,
        blue: 119 / 255
    )

    // MARK: - Main Layout

    var body: some View {
        GeometryReader { geometry in
            let landscape =
                geometry.size.width > geometry.size.height

            ZStack {
                background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {

                        header

                        audioSection

                        gameplaySection

                        helpSection

                        // Reuse the game's existing artwork.
                        Image("healer card")
                            .resizable()
                            .scaledToFit()
                            .frame(height: landscape ? 85 : 125)
                            .padding(.top, 4)
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                    .frame(
                        maxWidth: landscape ? 620 : 520
                    )
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .sheet(isPresented: $showTutorial) {
            HowToPlaySheetView()
        }
        .onAppear {
            updateAudio()
        }
        .onChange(of: musicEnabled) { _, _ in
            updateAudio()
        }
        .onChange(of: ambientEnabled) { _, _ in
            updateAudio()
        }
        .onChange(of: sfxEnabled) { _, _ in
            updateAudio()
        }
        .onChange(of: musicVolume) { _, _ in
            updateAudio()
        }
        .onChange(of: ambientVolume) { _, _ in
            updateAudio()
        }
        .onChange(of: sfxVolume) { _, _ in
            updateAudio()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Settings")
                .font(
                    .system(
                        size: 28,
                        weight: .bold,
                        design: .serif
                    )
                )
                .foregroundColor(brown)

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(
                        size: 15,
                        weight: .bold
                    ))
                    .foregroundColor(brown)
                    .frame(width: 40, height: 40)
                    .background(paper)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(
                                outline,
                                lineWidth: 1.3
                            )
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close settings")
        }
        .padding(.bottom, 4)
    }

    // MARK: - Audio Section

    private var audioSection: some View {
        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            sectionHeading(
                "Audio",
                icon: "speaker.wave.2.fill"
            )

            Divider()

            audioControl(
                title: "Background Music",
                icon: "music.note",
                enabled: $musicEnabled,
                volume: $musicVolume
            )

            Divider()

            audioControl(
                title: "Ambient Sounds",
                icon: "waveform",
                enabled: $ambientEnabled,
                volume: $ambientVolume
            )

            Divider()

            audioControl(
                title: "Sound Effects",
                icon: "speaker.wave.2",
                enabled: $sfxEnabled,
                volume: $sfxVolume
            )
        }
        .padding(18)
        .paperCard(paper, border: outline)
    }

    // MARK: - Audio Control

    private func audioControl(
        title: String,
        icon: String,
        enabled: Binding<Bool>,
        volume: Binding<Double>
    ) -> some View {

        VStack(spacing: 12) {

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .frame(width: 26)
                    .foregroundColor(brown)

                Text(title)
                    .font(.system(
                        size: 15,
                        weight: .medium
                    ))
                    .foregroundColor(brown)

                Spacer()

                Toggle(title, isOn: enabled)
                    .labelsHidden()
                    .tint(brown)
            }

            if enabled.wrappedValue {
                HStack(spacing: 12) {
                    Image(systemName: "speaker")
                        .foregroundColor(
                            brown.opacity(0.65)
                        )

                    Slider(
                        value: volume,
                        in: 0...1
                    )
                    .tint(brown)

                    Text(
                        "\(Int((volume.wrappedValue * 100).rounded()))%"
                    )
                    .font(.caption.monospacedDigit())
                    .foregroundColor(brown)
                    .frame(width: 42, alignment: .trailing)
                }
            }
        }
        .animation(
            .easeInOut(duration: 0.2),
            value: enabled.wrappedValue
        )
    }

    // MARK: - Gameplay

    private var gameplaySection: some View {
        VStack(
            alignment: .leading,
            spacing: 15
        ) {
            sectionHeading(
                "Gameplay",
                icon: "gamecontroller.fill"
            )

            Divider()

            HStack(spacing: 12) {
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .font(.system(size: 18))
                    .frame(width: 26)
                    .foregroundColor(brown)

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    Text("Haptic Feedback")
                        .font(.system(
                            size: 15,
                            weight: .medium
                        ))

                    Text("Vibration during gameplay")
                        .font(.caption)
                        .foregroundColor(
                            brown.opacity(0.65)
                        )
                }

                Spacer()

                Toggle(
                    "Haptic Feedback",
                    isOn: $hapticsEnabled
                )
                .labelsHidden()
                .tint(brown)
            }
            .foregroundColor(brown)
        }
        .padding(18)
        .paperCard(paper, border: outline)
    }

    // MARK: - Help

    private var helpSection: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            sectionHeading(
                "Help",
                icon: "questionmark.circle.fill"
            )

            Divider()

            Button {
                showTutorial = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 18))
                        .frame(width: 26)

                    Text("How to Play")
                        .font(.system(
                            size: 15,
                            weight: .medium
                        ))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                }
                .foregroundColor(brown)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Open game instructions")
        }
        .padding(18)
        .paperCard(paper, border: outline)
    }

    // MARK: - Shared Header

    private func sectionHeading(
        _ title: String,
        icon: String
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 17))

            Text(title)
                .font(
                    .system(
                        size: 19,
                        weight: .bold,
                        design: .serif
                    )
                )
        }
        .foregroundColor(brown)
    }

    // MARK: - Apply Audio Settings

    private func updateAudio() {
        AudioManager.shared.applySettings(
            musicEnabled: musicEnabled,
            ambientEnabled: ambientEnabled,
            sfxEnabled: sfxEnabled,
            musicVolume: musicVolume,
            ambientVolume: ambientVolume,
            sfxVolume: sfxVolume
        )
    }
}

// MARK: - Paper Card Style

private struct SettingsPaperCard: ViewModifier {
    let paper: Color
    let border: Color

    func body(content: Content) -> some View {
        content
            .background(paper)
            .clipShape(
                RoundedRectangle(cornerRadius: 15)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        border,
                        lineWidth: 1.3
                    )
            }
    }
}

private extension View {
    func paperCard(
        _ paper: Color,
        border: Color
    ) -> some View {
        modifier(
            SettingsPaperCard(
                paper: paper,
                border: border
            )
        )
    }
}

#Preview {
    SettingsView()
}
