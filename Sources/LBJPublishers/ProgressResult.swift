import Combine
import Foundation

extension Publishers {

  /// A publisher that emits a tuple representing the progress(range: 0 ~ 1) and result.
  public final class ProgressResult<R, Loader: ProgressResultLoader>: Publisher where R == Loader.R {

    public typealias Output = LoadResult<R>
    public typealias Failure = Error

    let loader: Loader

    public init(loader: Loader) {
      self.loader = loader
    }

    public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
      let subscription = ProgressResultSubscription(subscriber: subscriber, loader: loader)
      subscriber.receive(subscription: subscription)
    }
  }
}

private final class ProgressResultSubscription<R, Loader: ProgressResultLoader, S: Subscriber>: Subscription
where R == Loader.R, S.Input == LoadResult<R>, S.Failure == Error {

  var subscriber: S?
  let loader: Loader

  init(subscriber: S, loader: Loader) {
    self.subscriber = subscriber
    self.loader = loader
  }

  func request(_ demand: Subscribers.Demand) {
    loader.startLoading(
      progress: { [weak self] progress in
        _ = self?.subscriber?.receive(.init(progress: progress, result: nil))
      },
      completion: { [weak self] result, error in
        if let result = result {
          _ = self?.subscriber?.receive(.init(progress: 1, result: result))
          self?.subscriber?.receive(completion: .finished)

        } else if let error = error {
          self?.subscriber?.receive(completion: .failure(error))

        } else {
          fatalError("The completed block should have result or error")
        }
      })
  }

  func cancel() {
    loader.cancelLoading()
    subscriber = nil
  }
}

/// A type that can load the result with progress.
public protocol ProgressResultLoader: AnyObject {
  associatedtype R

  /// Start loading the result.
  /// - Parameters:
  ///   - progress: A closure called when the progress changed.
  ///   - completion: A closure called after loading compeleted.
  func startLoading(progress: @escaping (Double) -> Void, completion: @escaping (R?, Error?) -> Void)

  /// Cancel loading the result.
  func cancelLoading()
}

/// The value type emitted by `Publishers.ProgressResult`.
public struct LoadResult<R> {
  /// The loading progress.
  public let progress: Double

  /// The result after loading completed.
  public let result: R?

  public init(progress: Double, result: R?) {
    self.progress = progress
    self.result = result
  }
}
