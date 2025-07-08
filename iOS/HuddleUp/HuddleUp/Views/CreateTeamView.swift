import SwiftUI

struct CreateTeamView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var teamViewModel: TeamViewModel
    
    @State private var teamName = ""
    @State private var teamDescription = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, description
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Create Team")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Start collaborating with your team")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                VStack(spacing: 16) {
                    // Team Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Team Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        TextField("Enter team name", text: $teamName)
                            .focused($focusedField, equals: .name)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(focusedField == .name ? Color.blue : Color.clear, lineWidth: 2)
                            )
                    }
                    
                    // Team Description Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (Optional)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        TextField("What's this team about?", text: $teamDescription, axis: .vertical)
                            .focused($focusedField, equals: .description)
                            .lineLimit(3...6)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(focusedField == .description ? Color.blue : Color.clear, lineWidth: 2)
                            )
                    }
                }
                
                Spacer()
                
                // Create Button
                Button(action: createTeam) {
                    HStack {
                        if teamViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        
                        Text("Create Team")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isFormValid ? Color.blue : Color.gray)
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
            }
        }
        .onAppear {
            focusedField = .name
        }
        .onSubmit {
            if focusedField == .name {
                focusedField = .description
            } else if isFormValid {
                createTeam()
            }
        }
    }
    
    private var isFormValid: Bool {
        !teamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func createTeam() {
        let trimmedName = teamName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = teamDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        teamViewModel.createTeam(
            name: trimmedName,
            description: trimmedDescription
        )
        
        // The view will be dismissed by the TeamViewModel when successful
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !teamViewModel.showingError {
                dismiss()
            }
        }
    }
}

#Preview {
    CreateTeamView(teamViewModel: TeamViewModel())
} 