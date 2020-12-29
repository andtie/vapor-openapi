import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    [
        testCase(vapor_openapiTests.allTests)
    ]
}
#endif
