// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "Ayami",
  platforms: [
    .macOS(.v26),
    .iOS(.v18)
  ],
  products: [
    .executable(name: "Ayami", targets: ["Ayami"])
  ],
  dependencies: [
    .package(
      url: "https://github.com/gonzalezreal/textual",
      exact: "0.5.0"
    )
  ],
  targets: [
    .executableTarget(
      name: "Ayami",
      dependencies: [
        .product(name: "Textual", package: "textual")
      ],
      resources: [
        .copy("Resources")
      ]
    ),
    .testTarget(
      name: "AyamiTests",
      dependencies: ["Ayami"]
    ),
  ]
)
