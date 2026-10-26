import Foundation
import Testing

#if !SWIFT_PACKAGE
struct ReleaseVersionTests {
  @Test func testsVersion15Build21() {
    #expect(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String == "1.5")
    #expect(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String == "21")
  }
}
#endif
