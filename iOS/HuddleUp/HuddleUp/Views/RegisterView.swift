import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var showingRegister: Bool
    
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, username, password, confirmPassword, firstName, lastName
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 20) {
                    HStack {
                        Button(action: {
                            showingRegister = false
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    
                    // Logo
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                        .padding(.top, 20)
                    
                    VStack(spacing: 8) {
                        Text("Join Huddle Up")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Create your account")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(minHeight: 200)
                
                // Form
                VStack(spacing: 20) {
                    // Name Fields
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("First Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            TextField("John", text: $firstName)
                                .textContentType(.givenName)
                                .focused($focusedField, equals: .firstName)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(focusedField == .firstName ? Color.blue : Color.clear, lineWidth: 2)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Last Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            TextField("Doe", text: $lastName)
                                .textContentType(.familyName)
                                .focused($focusedField, equals: .lastName)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(focusedField == .lastName ? Color.blue : Color.clear, lineWidth: 2)
                                )
                        }
                    }
                    
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
                    
                    // Username Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        TextField("username", text: $username)
                            .textContentType(.username)
                            .autocapitalization(.none)
                            .focused($focusedField, equals: .username)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(focusedField == .username ? Color.blue : Color.clear, lineWidth: 2)
                            )
                        
                        if !username.isEmpty && !isValidUsername {
                            Text("Username must be 3-30 characters, letters, numbers, and underscore only")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
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
                            .textContentType(.newPassword)
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
                        
                        if !password.isEmpty && !isValidPassword {
                            Text("Password must be at least 6 characters")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Confirm Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Group {
                                if showConfirmPassword {
                                    TextField("Confirm your password", text: $confirmPassword)
                                } else {
                                    SecureField("Confirm your password", text: $confirmPassword)
                                }
                            }
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .confirmPassword)
                            
                            Button(action: {
                                showConfirmPassword.toggle()
                            }) {
                                Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(focusedField == .confirmPassword ? Color.blue : Color.clear, lineWidth: 2)
                        )
                        
                        if !confirmPassword.isEmpty && !passwordsMatch {
                            Text("Passwords do not match")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Create Account Button
                    Button(action: {
                        authViewModel.register(
                            email: email,
                            username: username,
                            password: password,
                            firstName: firstName,
                            lastName: lastName
                        )
                    }) {
                        HStack {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text("Create Account")
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
                    
                    // Terms and Privacy
                    Text("By creating an account, you agree to our Terms of Service and Privacy Policy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                        .padding(.top, 10)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
        .background(Color(.systemBackground))
        .onSubmit {
            switch focusedField {
            case .firstName:
                focusedField = .lastName
            case .lastName:
                focusedField = .email
            case .email:
                focusedField = .username
            case .username:
                focusedField = .password
            case .password:
                focusedField = .confirmPassword
            case .confirmPassword:
                if isFormValid {
                    authViewModel.register(
                        email: email,
                        username: username,
                        password: password,
                        firstName: firstName,
                        lastName: lastName
                    )
                }
            case .none:
                break
            }
        }
        .onAppear {
            focusedField = .firstName
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !username.isEmpty && !password.isEmpty &&
        !confirmPassword.isEmpty && !firstName.isEmpty && !lastName.isEmpty &&
        isValidUsername && isValidPassword && passwordsMatch
    }
    
    private var isValidUsername: Bool {
        let usernameRegex = "^[a-zA-Z0-9_]{3,30}$"
        let usernamePredicate = NSPredicate(format:"SELF MATCHES %@", usernameRegex)
        return usernamePredicate.evaluate(with: username)
    }
    
    private var isValidPassword: Bool {
        password.count >= 6
    }
    
    private var passwordsMatch: Bool {
        password == confirmPassword
    }
}

#Preview {
    RegisterView(showingRegister: .constant(true))
        .environmentObject(AuthViewModel())
} 