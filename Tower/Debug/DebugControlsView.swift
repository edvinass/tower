import SwiftUI

struct DebugControlsView: View {
    @ObservedObject var gravity: GravityController

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Sim Tilt", isOn: $gravity.useDebugInput)
                .font(.caption2)
            if gravity.useDebugInput {
                HStack {
                    Text("Roll")
                        .font(.caption2)
                        .frame(width: 28, alignment: .leading)
                    Slider(value: $gravity.debugRoll, in: -30...30)
                }
                HStack {
                    Text("Pitch")
                        .font(.caption2)
                        .frame(width: 28, alignment: .leading)
                    Slider(value: $gravity.debugPitch, in: -30...30)
                }
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .frame(width: 180)
    }
}
