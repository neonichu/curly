import PackageDescription

let package = Package(
    name: "Curly",
    targets: [
      Target(name: "curly-cli", dependencies: [.Target(name: "Curly")]),
    ],
    dependencies: [
      .Package(url: "https://github.com/neonichu/curl", majorVersion: 1),
      .Package(url: "https://github.com/jensravens/Interstellar", majorVersion: 1)
    ]
)
