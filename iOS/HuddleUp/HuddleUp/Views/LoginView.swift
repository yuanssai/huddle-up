import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var showingRegister: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 20) {
                    Spacer()
                    
                    // Logo
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .padding(.top, 40)
                    
                    VStack(spacing: 8) {
                        Text("Welcome to Huddle Up")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Sign in to your workspace")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .frame(minHeight: 300)
                
                // Form
                VStack(spacing: 20) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        TextField("your@email.com", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .focused($focusedField, equals: .email)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(focusedField == .email ? Color.blue : Color.clear, lineWidth: 2)
                            )
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Group {
                                if showPassword {
                                    TextField("Enter your password", text: $password)
                                } else {
                                    SecureField("Enter your password", text: $password)
                                }
                            }
                            .textContentType(.password)
                            .focused($focusedField, equals: .password)
                            
                            Button(action: {
                                showPassword.toggle()
                            }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(focusedField == .password ? Color.blue : Color.clear, lineWidth: 2)
                        )
                    }
                    
                    // Sign In Button
                    Button(action: {
                        authViewModel.login(email: email, password: password)
                    }) {
                        HStack {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text("Sign In")
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
                    .disabled(!isFormValid || authViewModel.isLoading)
                    .padding(.top, 10)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(height: 1)
                        
                        Text("or")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                        
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(height: 1)
                    }
                    .padding(.vertical, 20)
                    
                    // Sign Up Button
                    Button(action: {
                        showingRegister = true
                    }) {
                        Text("Create a new account")
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                    }
                    
                    // Demo Account Info
                    VStack(spacing: 8) {
                        Text("Demo Account")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            email = "test@example.com"
                            password = "password123"
                        }) {
                            Text("Use Demo Credentials")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
        .background(Color(.systemBackground))
        .onSubmit {
            if focusedField == .email {
                focusedField = .password
            } else if focusedField == .password && isFormValid {
                authViewModel.login(email: email, password: password)
            }
        }
        .onAppear {
            focusedField = .email
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
}

#Preview {
    LoginView(showingRegister: .constant(false))
        .environmentObject(AuthViewModel())
} 