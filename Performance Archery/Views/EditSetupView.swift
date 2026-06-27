//
//  EditSetupView.swift
//  Performance Archery
//
//  Created by Luke Myers on 27/06/2026.
//

import SwiftUI

struct EditSetupView: View {
    @Bindable var viewModel: EquipmentViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var description: AttributedString = ""
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Setup Details")) {
                    TextField("Name", text: $name)
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
                
                if viewModel.setups.count > 1 {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Text("Delete Setup")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle("Edit Setup")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let activeSetup = viewModel.setups.first(where: { $0.id == viewModel.activeSetupId }) {
                    name = activeSetup.name
                    description = activeSetup.description
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.updateActiveSetup(name: name, description: description)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Delete Setup?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.deleteActiveSetup()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this setup? This action cannot be undone.")
            }
        }
    }
}

#Preview {
    EditSetupView(viewModel: EquipmentViewModel())
}
