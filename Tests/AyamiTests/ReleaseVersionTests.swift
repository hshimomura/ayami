import Foundation
import Testing

#if !SWIFT_PACKAGE
struct ReleaseVersionTests {
  @Test func testsVersion14Build20() {
    #expect(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String == "1.4")
    #expect(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String == "20")
  }
}
#endif
