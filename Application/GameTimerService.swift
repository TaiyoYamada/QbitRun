import Foundation

/// ゲームの残り時間を管理するタイマーサービス
@Observable
@MainActor
public final class GameTimerService {

    public private(set) var remainingTime: Int

    private let duration: Int

    private var timerTask: Task<Void, Never>?

    public var onTimeUp: (() -> Void)?

    public init(duration: Int = 60) {
        self.duration = duration
        self.remainingTime = duration
    }

    public func start() {
        remainingTime = duration
        resume()
    }

    public func resume() {
        guard timerTask == nil else { return }

        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))

                guard let self else { break }

                self.remainingTime -= 1

                if self.remainingTime <= 0 {
                    self.onTimeUp?()
                    break
                }
            }
        }
    }

    public func pause() {
        timerTask?.cancel()
        timerTask = nil
    }

    public func reset() {
        pause()
        remainingTime = duration
    }
}
