import SwiftUI
import MapKit

struct LookAroundMapView: View {
    @State private var lookAroundScene: MKLookAroundScene?
    let homeCoord: CLLocationCoordinate2D
    
    var body: some View {
        MapReader { context in
            Map {
                Annotation("Home", coordinate: homeCoord) {
                    Button("Look Around") {
                        Task {
                            let request = MKLookAroundSceneRequest(coordinate: homeCoord)
                            lookAroundScene = try? await request.scene
                        }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if let scene = lookAroundScene {
                    LookAroundPreview(initialScene: scene)
                        .frame(height: 200)
                }
            }
        }
    }
}
