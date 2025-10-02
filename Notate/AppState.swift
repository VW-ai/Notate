// AppState.swift
import Foundation
import Combine   // ← 关键：ObservableObject 在 Combine 里

@MainActor
final class AppState: ObservableObject {
    let engine = CaptureEngine()
    // 至少有一个 @Published 字段更稳（不是必须，但可避免编译器抽风）
    @Published var lastCapturedPreview: String = ""
}



