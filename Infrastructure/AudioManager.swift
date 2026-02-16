// SPDX-License-Identifier: MIT
// Infrastructure/AudioManager.swift

import AVFoundation
import SwiftUI

/// アプリ全体のオーディオ管理を行うクラス
@Observable
final class AudioManager {
    
    // MARK: - Enums
    
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
        case combo = "sfx_combo" // Optional
    }
    
    // MARK: - Properties
    
    // MARK: - Properties
    
    private var bgmPlayer: AVAudioPlayer?
    // SFXPool: 同時再生を可能にするため、各SFXタイプごとに複数のプレイヤーを保持する
    private var sfxPlayers: [SFX: [AVAudioPlayer]] = [:]
    
    /// BGMの音量 (0.0 - 1.0)
    var bgmVolume: Float = UserDefaults.standard.float(forKey: "bgmVolume") == 0 ? 0.5 : UserDefaults.standard.float(forKey: "bgmVolume") {
        didSet {
            bgmPlayer?.volume = bgmVolume
            UserDefaults.standard.set(bgmVolume, forKey: "bgmVolume")
        }
    }
    
    /// SFXの音量 (0.0 - 1.0)
    var sfxVolume: Float = UserDefaults.standard.float(forKey: "sfxVolume") == 0 ? 1.0 : UserDefaults.standard.float(forKey: "sfxVolume") {
        didSet {
            UserDefaults.standard.set(sfxVolume, forKey: "sfxVolume")
        }
    }
    
    // MARK: - Initialization
    
    init() {
        configureAudioSession()
        preloadSFX()
    }
    
    // MARK: - Audio Session
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    // MARK: - BGM Control
    
    /// BGMを再生する
    /// - Parameter bgm: 再生するBGMの種類
    func playBGM(_ bgm: BGM) {
        // 同じ曲が再生中の場合は何もしない
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
            bgmPlayer?.numberOfLoops = -1 // 無限ループ
            bgmPlayer?.volume = bgmVolume
            bgmPlayer?.prepareToPlay()
            bgmPlayer?.play()
        } catch {
            print("Failed to play BGM: \(error)")
        }
    }
    
    /// BGMを停止する
    /// - Parameter fadeOut: フェードアウト時間（秒）
    func stopBGM(fadeOut: TimeInterval = 0.5) {
        if let player = bgmPlayer, player.isPlaying {
            player.setVolume(0, fadeDuration: fadeOut)
        }
    }
    
    // MARK: - SFX Control
    
    /// 効果音をプリロードする
    private func preloadSFX() {
        // 一般的なSFXを事前にいくつか作っておく
        for sfx in [SFX.click, .set, .combo, .miss, .success] {
            preparePlayer(for: sfx)
        }
    }
    
    /// プレイヤーを準備してプールに追加する
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
    
    /// 効果音を再生する
    /// - Parameter sfx: 再生する効果音の種類
    func playSFX(_ sfx: SFX) {
        // 利用可能な（再生中でない）プレイヤーを探す
        var playerToUse: AVAudioPlayer?
        
        if let players = sfxPlayers[sfx] {
            playerToUse = players.first(where: { !$0.isPlaying })
        }
        
        // 利用可能なものがなければ新しく作る
        if playerToUse == nil {
            playerToUse = preparePlayer(for: sfx)
        }
        
        guard let player = playerToUse else { return }
        
        player.volume = sfxVolume
        player.currentTime = 0
        player.play()
    }
}
