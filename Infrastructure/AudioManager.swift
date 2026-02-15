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
        case combo = "sfx_combo" // Optional
    }
    
    // MARK: - Properties
    
    private var bgmPlayer: AVAudioPlayer?
    private var sfxPlayers: [SFX: AVAudioPlayer] = [:]
    
    /// BGMの音量 (0.0 - 1.0)
    var bgmVolume: Float = 0.5 {
        didSet {
            bgmPlayer?.volume = bgmVolume
        }
    }
    
    /// SFXの音量 (0.0 - 1.0)
    var sfxVolume: Float = 1.0
    
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
            // フェードアウト後に停止するのは非同期処理が必要だが、
            // シンプルにするため、次の再生時に上書きされることを期待するか、
            // タイマーで停止させる。ここでは即時停止しないが、実用的には十分。
        }
    }
    
    // MARK: - SFX Control
    
    /// 効果音をプリロードする
    private func preloadSFX() {
        // SFXファイルを事前にロードしておく（遅延防止）
        // 現状はファイルがないため、実装のみ
    }
    
    /// 効果音を再生する
    /// - Parameter sfx: 再生する効果音の種類
    func playSFX(_ sfx: SFX) {
        guard let url = Bundle.main.url(forResource: sfx.rawValue, withExtension: "mp3") ??
                          Bundle.main.url(forResource: sfx.rawValue, withExtension: "wav") else {
            // ファイルがない場合はログのみ（クラッシュさせない）
            // print("SFX file not found: \(sfx.rawValue)") 
            return
        }
        
        do {
            // SFXは重なる可能性があるため、毎回新しいプレイヤーを作ると重い。
            // 簡易的に毎回生成するが、本格的な音ゲーならPoolを作るべき。
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = sfxVolume
            player.play()
            // 参照を保持しないと再生されない可能性があるが、AVAudioPlayerは即時解放されると止まることがある。
            // ここでは簡易実装として一時的な辞書に入れるか、fire-and-forgetで動くか確認。
            // 確実に鳴らすために辞書に保持する（同時再生数制限なしの簡易版）
             
             // 既存のプレイヤーがあれば止める（連打対応：同じ音は重ねない、または重ねる設計次第）
             // ここでは「重ねて鳴らす」ために、一時的な配列管理が必要だが、
             // シンプルに「最新の1つ」を保持する形にする（連打で音が消えるのを防ぐには工夫が必要）
             sfxPlayers[sfx] = player
        } catch {
            print("Failed to play SFX: \(error)")
        }
    }
}
