import SwiftUI

struct JoinTeamView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var teamViewModel: TeamViewModel
    
    @State private var inviteCode = ""
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("Join Team")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Enter an invite code to join a team")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                VStack(spacing: 16) {
                    // Invite Code Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Invite Code")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        TextField("Enter invite code", text: $inviteCode)
                            .focused($isFieldFocused)
                            .textContentType(.oneTimeCode)
                            .autocapitalization(.none)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isFieldFocused ? Color.green : Color.clear, lineWidth: 2)
                            )
                    }
                    
                    // Info Section
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            
                            Text("Ask your team admin for an invite code")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        
                        HStack {
                            Image(systemName: "qrcode")
                                .foregroundColor(.blue)
                            
                            Text("Invite codes are UUID format")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                    }
                    .padding(.top, 8)
                }
                
                Spacer()
                
                // Join Button
                Button(action: joinTeam) {
                    HStack {
                        if teamViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        
                        Text("Join Team")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isFormValid ? Color.green : Color.gray)
                    )
                }
                .disabled(!isFormValid || teamViewModel.isLoading)
                .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Paste") {
                        if let clipboardText = UIPasteboard.general.string {
                            inviteCode = clipboardText.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    }
                    .disabled(UIPasteboard.general.string == nil)
                }
            }
        }
        .onAppear {
            isFieldFocused = true
        }
        .onSubmit {
            if isFormValid {
                joinTeam()
            }
        }
    }
    
    private var isFormValid: Bool {
        !inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func joinTeam() {
        let trimmedCode = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines)
        
        teamViewModel.joinTeam(inviteCode: trimmedCode)
        
        // The view will be dismissed by the TeamViewModel when successful
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !teamViewModel.showingError {
                dismiss()
            }
        }
    }
}

#Preview {
    JoinTeamView(teamViewModel: TeamViewModel())
} 