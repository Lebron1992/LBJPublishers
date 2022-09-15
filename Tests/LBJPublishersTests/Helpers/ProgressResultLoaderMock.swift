import Combine
import Foundation
@testable import LBJPublishers

final class ProgressResultLoaderMock: ProgressResultLoader {

  let progressValues: [Double]
  let result: String
  let delay: Double

  private var progressSubscription: AnyCancellable?

  init(progressValues: [Double], result: String, delay: Double) {
    self.progressValues = progressValues
    self.result = result
    self.delay = delay
  }

  func startLoading(
    progress: @escaping (Double) -> Void,
    completion: @escaping (String?, Error?) -> Void
  ) {
    let progressPublisher = progressValues.publisher
    let delayPublisher = Timer.publish(every: delay, on: .main, in: .default).autoconnect()

    progressSubscription = Publishers.Zip(progressPublisher, delayPublisher)
      .map { $0.0 }
      .sink(
        receiveCompletion: { _ in },
        receiveValue: { [weak self] pgs in
          print(pgs)
          if pgs == 1 {
            completion(self?.result, nil)
          } else {
            progress(pgs)
          }
        })
  }

  func cancelLoading() {
    progressSubscription?.cancel()
  }
}
