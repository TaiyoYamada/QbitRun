import Foundation

/// BGMとSEの再生・停止・音量制御を抽象化するプロトコル
@MainActor
protocol AudioPlayable: AnyObject {
    func playBGM(_ bgm: AudioManager.BGM)
    func stopBGM(fadeOut: TimeInterval)
    func playSFX(_ sfx: AudioManager.SFX)
    var bgmVolume: Float { get set }
    var sfxVolume: Float { get set }
}
