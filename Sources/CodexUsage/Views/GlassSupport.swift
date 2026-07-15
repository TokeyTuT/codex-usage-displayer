import SwiftUI

extension View {
  @ViewBuilder
  func codexGlass<S: Shape>(in shape: S) -> some View {
    if #available(macOS 26.0, *) {
      self.glassEffect(.regular, in: shape)
    } else {
      self
        .background(.ultraThinMaterial, in: shape)
        .overlay(shape.stroke(.white.opacity(0.16), lineWidth: 0.7))
    }
  }

  @ViewBuilder
  func codexGlassButton() -> some View {
    if #available(macOS 26.0, *) {
      self.buttonStyle(.glass)
    } else {
      self
        .buttonStyle(.borderless)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.thinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 0.7))
    }
  }
}

extension Color {
  static let codexMint = Color(red: 0.31, green: 0.84, blue: 0.66)
  static let codexAmber = Color(red: 0.96, green: 0.67, blue: 0.28)
  static let codexCoral = Color(red: 0.94, green: 0.38, blue: 0.34)
}
