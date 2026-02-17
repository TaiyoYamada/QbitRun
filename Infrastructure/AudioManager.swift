
import AVFoundation
import SwiftUI

@Observable
final class AudioManager {

    enum BGM: String {
        case menu = "bgm_menu"
        case game = "bgm_game"
        case result = "bgm_result"
    }

    enum SFX: String {
        case click = "sfx_click"
        case success = "sfx_success"
        case miss = "sfx_miss"
        case set = "sfx_set"
        case clear = "sfx_clear"
        case button = "sfx_button"
        case combo = "sfx_combo"
    }

    private var bgmPlayer: AVAudioPlayer?
    private var sfxPlayers: [SFX: [AVAudioPlayer]] = [:]

    var bgmVolume: Float = UserDefaults.standard.float(forKey: "bgmVolume") == 0 ? 0.5 : UserDefaults.standard.float(forKey: "bgmVolume") {
        didSet {
            bgmPlayer?.volume = bgmVolume
            UserDefaults.standard.set(bgmVolume, forKey: "bgmVolume")
        }
    }

    var sfxVolume: Float = UserDefaults.standard.float(forKey: "sfxVolume") == 0 ? 1.0 : UserDefaults.standard.float(forKey: "sfxVolume") {
        didSet {
            UserDefaults.standard.set(sfxVolume, forKey: "sfxVolume")
        }
    }

    init() {
        configureAudioSession()
        preloadSFX()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    func playBGM(_ bgm: BGM) {
        if let player = bgmPlayer, player.isPlaying, player.url?.lastPathComponent.contains(bgm.rawValue) == true {
            return
        }

        stopBGM()

        guard let url = Bundle.main.url(forResource: bgm.rawValue, withExtension: "mp3") ??
                          Bundle.main.url(forResource: bgm.rawValue, withExtension: "wav") else {
            print("BGM file not found: \(bgm.rawValue)")
            return
        }

        do {
            bgmPlayer = try AVAudioPlayer(contentsOf: url)
            bgmPlayer?.numberOfLoops = -1
            bgmPlayer?.volume = bgmVolume
            bgmPlayer?.prepareToPlay()
            bgmPlayer?.play()
        } catch {
            print("Failed to play BGM: \(error)")
        }
    }

    func stopBGM(fadeOut: TimeInterval = 0.5) {
        if let player = bgmPlayer, player.isPlaying {
            player.setVolume(0, fadeDuration: fadeOut)
        }
    }

    private func preloadSFX() {
        for sfx in [SFX.click, .set, .combo, .miss, .success] {
            preparePlayer(for: sfx)
        }
    }

    @discardableResult
    private func preparePlayer(for sfx: SFX) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: sfx.rawValue, withExtension: "mp3") ??
                          Bundle.main.url(forResource: sfx.rawValue, withExtension: "wav") else {
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = sfxVolume
            player.prepareToPlay()

            if sfxPlayers[sfx] != nil {
                sfxPlayers[sfx]?.append(player)
            } else {
                sfxPlayers[sfx] = [player]
            }
            return player
        } catch {
            print("Failed to load SFX \(sfx): \(error)")
            return nil
        }
    }

    func playSFX(_ sfx: SFX) {
        var playerToUse: AVAudioPlayer?

        if let players = sfxPlayers[sfx] {
            playerToUse = players.first(where: { !$0.isPlaying })
        }

        if playerToUse == nil {
            playerToUse = preparePlayer(for: sfx)
        }

        guard let player = playerToUse else { return }

        player.volume = sfxVolume
        player.currentTime = 0
        player.play()
    }
}
