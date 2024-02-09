// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "swift-language-study",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.83.1"),
        // 🗄 An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.8.0"),
        // 🪶 Fluent driver for SQLite.
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
        .package(url: "https://github.com/binarybirds/swift-html", from: "1.6.0"),
        .package(url: "https://github.com/apple/swift-format", from: "509.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "SwiftHtml", package: "swift-html")
            ],
            path: "swift-language-study"
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .target(name: "App"),
                .product(name: "XCTVapor", package: "vapor"),

                // Workaround for https://github.com/apple/swift-package-manager/issues/6940
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "Fluent"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
            ],
            path: "swift-language-study-tests"
        )
    ]
)
