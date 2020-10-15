import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(vapor_openapiTests.allTests)
    ]
}
#endif
