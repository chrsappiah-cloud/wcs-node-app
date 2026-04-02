//
//  AddCircleMemberView.swift
//  GeoWCS - Add Member to Circle UI
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  SwiftUI view with phone number validation for adding members to circles.
//

import SwiftUI

struct AddCircleMemberView: View {
    @State private var memberName: String = ""
    @State private var phoneNumber: String = ""
    @State private var selectedRole: CircleMember.Role = .member
    @State private var validationError: String?
    @State private var suggestedCountry: String?
    @State private var isLoading = false
    @State private var successMessage: String?
    
    var circle: Circle
    @Environment(\.dismiss) var dismiss
    var onMemberAdded: (CircleMember) -> Void
    
    var isPhoneValid: Bool {
        !phoneNumber.isEmpty && PhoneNumberValidator.isValid(phoneNumber)
    }
    
    var canAddMember: Bool {
        !memberName.trimmingCharacters(in: .whitespaces).isEmpty &&
        isPhoneValid &&
        !isLoading
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Circle Info Section
                Section("Circle") {
                    Text(circle.name)
                        .font(.headline)
                    Text("\(circle.memberCount)/\(circle.maxMembers) members")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Member Details Section
                Section("Member Details") {
                    TextField("Member Name", text: $memberName)
                        .textContentType(.name)
                        .disabled(isLoading)
                    
                    // Phone Number Input with Real-time Validation
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            TextField("Phone Number", text: $phoneNumber)
                                .textContentType(.telephoneNumber)
                                .keyboardType(.phonePad)
                                .onReceive(phoneNumber.publisher.collect()) { newValue in
                                    validateAndFormatPhone()
                                }
                                .disabled(isLoading)
                            
                            if isPhoneValid {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        
                        if let error = validationError {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        if let country = suggestedCountry {
                            HStack(spacing: 6) {
                                Image(systemName: "globe")
                                    .foregroundColor(.blue)
                                Text(country)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // Supported Countries Reference
                        DisclosureGroup("Supported Countries") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(PhoneNumberValidator.getSupportedCountryCodes(), id: \.self) { code in
                                    if let info = PhoneNumberValidator.getCountryInfo(for: code) {
                                        HStack {
                                            Text(code)
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .frame(width: 40)
                                            Text(info.name)
                                                .font(.caption)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                
                // Role Selection
                Section("Role") {
                    Picker("Member Role", selection: $selectedRole) {
                        Text("Member").tag(CircleMember.Role.member)
                        Text("Admin").tag(CircleMember.Role.admin)
                    }
                    .disabled(isLoading)
                }
                
                // Action Buttons
                Section {
                    HStack(spacing: 12) {
                        Button(action: { dismiss() }) {
                            Label("Cancel", systemImage: "xmark")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isLoading)
                        
                        Button(action: addMember) {
                            if isLoading {
                                HStack(spacing: 6) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Adding...")
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                Label("Add Member", systemImage: "person.badge.plus")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canAddMember)
                    }
                    .listRowInsets(EdgeInsets())
                    .background(Color(.systemBackground))
                }
                
                // Success Message
                if let success = successMessage {
                    Section {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(success)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle("Add Member to Circle")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Validation & Actions
    
    private func validateAndFormatPhone() {
        guard !phoneNumber.isEmpty else {
            validationError = nil
            suggestedCountry = nil
            return
        }
        
        do {
            // Validate phone number
            let validatedPhone = try PhoneNumberValidator.validate(phoneNumber)
            phoneNumber = validatedPhone
            validationError = nil
            
            // Get suggested country
            suggestedCountry = PhoneNumberValidator.suggestCountry(phoneNumber)
        } catch let error as PhoneValidationError {
            validationError = error.errorDescription
            suggestedCountry = nil
        } catch {
            validationError = "Invalid phone number"
            suggestedCountry = nil
        }
    }
    
    private func addMember() {
        isLoading = true
        
        defer { isLoading = false }
        
        do {
            // Final validation
            let validatedPhone = try PhoneNumberValidator.validate(phoneNumber)
            let trimmedName = memberName.trimmingCharacters(in: .whitespaces)
            
            // Create member
            let newMember = try CircleMember(
                name: trimmedName,
                phoneNumber: validatedPhone,
                role: selectedRole
            )
            
            // Success
            successMessage = "✓ \(trimmedName) added successfully"
            onMemberAdded(newMember)
            
            // Dismiss after brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
        } catch let error as PhoneValidationError {
            validationError = error.errorDescription
        } catch let error as CircleMemberError {
            validationError = error.errorDescription
        } catch {
            validationError = "Failed to add member: \(error.localizedDescription)"
        }
    }
}

// MARK: - Create Circle with Members View

struct CreateCircleView: View {
    @State private var circleName: String = ""
    @State private var circleDescription: String = ""
    @State private var maxMembers: Int = 10
    @State private var isPrivate: Bool = true
    @State private var members: [CircleMember] = []
    @State private var showAddMember = false
    @State private var validationError: String?
    @State private var isLoading = false
    
    @Environment(\.dismiss) var dismiss
    var onCircleCreated: (Circle, [CircleMember]) -> Void
    
    var canCreateCircle: Bool {
        !circleName.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Circle Details") {
                    TextField("Circle Name", text: $circleName)
                        .textContentType(.none)
                        .disabled(isLoading)
                    
                    TextField("Description (optional)", text: $circleDescription)
                        .disabled(isLoading)
                    
                    Stepper("Max Members: \(maxMembers)", value: $maxMembers, in: 2...20)
                        .disabled(isLoading)
                    
                    Toggle("Private Circle", isOn: $isPrivate)
                        .disabled(isLoading)
                }
                
                Section("Members (\(members.count))") {
                    if members.isEmpty {
                        Text("No members added yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(members) { member in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(member.name)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text(member.role.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                Text(member.phoneNumber)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onDelete(perform: removeMembers)
                    }
                    
                    Button(action: { showAddMember = true }) {
                        Label("Add Member", systemImage: "person.badge.plus")
                    }
                    .disabled(members.count >= maxMembers || isLoading)
                }
                
                if let error = validationError {
                    Section {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundColor(.red)
                            Text(error)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section {
                    Button(action: createCircle) {
                        if isLoading {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Creating...")
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            Label("Create Circle", systemImage: "checkmark.circle")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canCreateCircle)
                }
            }
            .navigationTitle("Create Circle")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddMember) {
                if let tempCircle = try? Circle(
                    name: circleName,
                    description: circleDescription,
                    creatorId: UUID().uuidString,
                    maxMembers: maxMembers,
                    isPrivate: isPrivate
                ) {
                    AddCircleMemberView(circle: tempCircle) { newMember in
                        members.append(newMember)
                        showAddMember = false
                    }
                }
            }
        }
    }
    
    private func removeMembers(at offsets: IndexSet) {
        members.remove(atOffsets: offsets)
    }
    
    private func createCircle() {
        isLoading = true
        validationError = nil
        
        defer { isLoading = false }
        
        do {
            let trimmedName = circleName.trimmingCharacters(in: .whitespaces)
            var circle = try Circle(
                name: trimmedName,
                description: circleDescription.isEmpty ? nil : circleDescription,
                creatorId: UUID().uuidString,
                maxMembers: maxMembers,
                isPrivate: isPrivate
            )
            
            onCircleCreated(circle, members)
            dismiss()
        } catch let error as CircleError {
            validationError = error.errorDescription
        } catch {
            validationError = "Failed to create circle: \(error.localizedDescription)"
        }
    }
}

#Preview {
    var previewCircle: Circle {
        do {
            return try Circle(
                name: "Family Circle",
                description: "Close family safety circle",
                creatorId: UUID().uuidString,
                maxMembers: 10
            )
        } catch {
            fatalError("Failed to create preview circle")
        }
    }
    
    return AddCircleMemberView(circle: previewCircle) { _ in }
}
