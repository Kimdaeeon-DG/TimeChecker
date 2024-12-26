import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @Binding var showingDocumentPicker: Bool
    let backupAction: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isShowing = false
                    }
                }
            
            HStack {
                Spacer()
                
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation {
                                isShowing = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                    
                    Button(action: backupAction) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("백업")
                        }
                        .foregroundColor(.primary)
                        .padding()
                    }
                    
                    Button(action: {
                        showingDocumentPicker = true
                        isShowing = false
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("복원")
                        }
                        .foregroundColor(.primary)
                        .padding()
                    }
                    
                    Spacer()
                }
                .frame(width: 250)
                .background(Color(UIColor.systemBackground))
                .offset(x: isShowing ? 0 : 250)
            }
        }
    }
}

struct SideMenuView_Previews: PreviewProvider {
    static var previews: some View {
        SideMenuView(
            isShowing: .constant(true),
            showingDocumentPicker: .constant(false),
            backupAction: {}
        )
    }
}
