import CoreMotion
import SwiftUI
import Combine

class MotionManager: NSObject, ObservableObject {
    
    static let shared = MotionManager()
    
    private let manager = CMMotionManager()
    
    @Published var roll: Double = 0
    @Published var pitch: Double = 0
    
    override init() {
        super.init()
    }
    
    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(to: .main) { motion, _ in
            guard let motion = motion else { return }
            withAnimation(.linear(duration: 0.1)) {
                self.roll = motion.attitude.roll
                self.pitch = motion.attitude.pitch
            }
        }
    }
    
    func stop() {
        manager.stopDeviceMotionUpdates()
    }
}
