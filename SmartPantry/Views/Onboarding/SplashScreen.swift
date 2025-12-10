import SwiftUI

struct SplashScreen: View {
    @Binding var isActive: Bool
    
    var body: some View {
        VStack {
            Image(systemName: "fork.knife.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(.white)
            
            Text("SmartPantry")
                .font(.largeTitle)
                .bold()
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.accentColor)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    isActive = false
                }
            }
        }
    }
}
