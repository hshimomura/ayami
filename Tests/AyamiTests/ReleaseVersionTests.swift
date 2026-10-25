import Foundation
import Testing

#if !SWIFT_PACKAGE
struct ReleaseVersionTests {
  @Test func testsVersion13Build18() {
    #expect(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String == "1.3")
    #expect(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String == "18")
  }
}
#endif
