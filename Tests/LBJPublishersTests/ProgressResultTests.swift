import Combine
import XCTest
@testable import LBJPublishers

final class ProgressResultTests: XCTestCase {

  private var subscriptions: Set<AnyCancellable> = []

  override func tearDown() {
    super.tearDown()
    subscriptions = []
  }

  func test_completeLoading() {
    let progressValuesExpected = [0, 0.5, 1]
    var progressValuesResult: [Double] = []

    let stringResult = "success"
    var stringExpected: String?

    let loaderMock = ProgressResultLoaderMock(
      progressValues: progressValuesExpected,
      result: stringResult,
      delay: 0.2
    )

    let expectation = expectation(description: #function)

    Publishers.ProgressResult(loader: loaderMock)
      .receive(on: DispatchQueue.main)
      .sink(
        receiveCompletion: { _ in
          expectation.fulfill()
        },
        receiveValue: {
          let (progress, result) = $0
          progressValuesResult.append(progress)
          if progress == 1 {
            stringExpected = result
          }
        })
      .store(in: &subscriptions)

    waitForExpectations(timeout: 1, handler: nil)

    XCTAssertEqual(progressValuesResult, progressValuesExpected)
    XCTAssertEqual(stringResult, stringExpected)
  }

  func test_cancelLoading() {
    let progressValues = [0, 0.5, 1]
    let progressValuesExpected = [0, 0.5]
    var progressValuesResult: [Double] = []

    let result = "success"
    var stringExpected: String?

    let loaderMock = ProgressResultLoaderMock(
      progressValues: progressValues,
      result: result,
      delay: 0.2
    )

    let expectation = expectation(description: #function)

    Publishers.ProgressResult(loader: loaderMock)
      .receive(on: DispatchQueue.main)
      .sink(
        receiveCompletion: { _ in },
        receiveValue: {
          let (progress, result) = $0
          progressValuesResult.append(progress)
          if progress == 1 {
            stringExpected = result
          }
        })
      .store(in: &subscriptions)

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      self.subscriptions.forEach { $0.cancel() }
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 1, handler: nil)

    XCTAssertEqual(progressValuesResult, progressValuesExpected)
    XCTAssertNil(stringExpected)
  }
}
