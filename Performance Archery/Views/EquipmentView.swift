//
//  EquipmentView.swift
//  Performance Archery
//
//  Created by Luke Myers on 16/01/2026.
//

import SwiftUI
import Charts

struct EquipmentView: View {
    @State private var viewModel = EquipmentViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Units", selection: $viewModel.unitSystem) {
                        ForEach(UnitSystem.allCases) { system in
                            Text(system.label).tag(system)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                Section("Tiller") {
                    HStack {
                        TextField("Value", value: $viewModel.tillerDisplay, format: .number)
                            .keyboardType(.decimalPad)
                        Text(viewModel.unitSystem.tillerUnitLabel)
                            .foregroundStyle(.secondary)
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                Section("Bracing Height") {
                    HStack {
                        TextField("Value", value: $viewModel.bracingHeightDisplay, format: .number)
                            .keyboardType(.decimalPad)
                        Text(viewModel.unitSystem.bracingHeightUnitLabel)
                            .foregroundStyle(.secondary)
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                Section(header:
                    HStack {
                        Text("Sight Marks")
                        Spacer()
                        Button("Edit") { viewModel.showEditSightmarksSheet = true }
                    }
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        if viewModel.sightMarks.isEmpty {
                            Text("No sight marks yet. Add one below to get started.")
                                .foregroundStyle(.secondary)
                        } else {
                            Chart {
                                ForEach(viewModel.sortedSightMarks) { sm in
                                    let dist = viewModel.displayDistance(sm.distanceMeters)
                                    PointMark(x: .value("Dist", dist), y: .value("Sight", sm.sightValue))
                                    LineMark(x: .value("Dist", dist), y: .value("Sight", sm.sightValue))
                                        .interpolationMethod(.monotone)
                                }
                            }
                            .chartXScale(domain: viewModel.chartXDomain)
                            .chartXAxisLabel("Distance (\(viewModel.unitSystem.distanceUnitLabel))")
                            .chartYAxisLabel("Sight mark")
                            .chartXAxis {
                                AxisMarks(values: .stride(by: 10))
                            }
                            .chartYAxis {
                                AxisMarks(values: .automatic(desiredCount: 10))
                            }
                            .frame(minHeight: 250)
                        }
                        
                        HStack(spacing: 5) {
                            HStack {
                                TextField("0", value: $viewModel.inputDistance, format: .number)
                                    .keyboardType(.decimalPad)
                                    .frame(width: 30)
                                    .multilineTextAlignment(.trailing)
                                Text(viewModel.unitSystem.distanceUnitLabel).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: 60)
                            
                            HStack {
                                Text("Elevation:").foregroundStyle(.secondary)
                                TextField("0.0", value: $viewModel.inputSightValue, format: .number)
                                    .keyboardType(.decimalPad)
                                    .frame(width: 40)
                            }
                            .frame(maxWidth: 125)
                            
                            HStack {
                                Text("Extension:").foregroundStyle(.secondary)
                                TextField("0", value: $viewModel.inputExtensionValue, format: .number)
                                    .keyboardType(.numberPad)
                                    .frame(width: 25)
                            }
                            .frame(maxWidth: 115)
                        }
                        
                        Button {
                            viewModel.addSightMark()
                        } label: {
                            Text("Add Sightmark")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!viewModel.canAddSightMark)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle(viewModel.setups.first(where: { $0.id == viewModel.activeSetupId })?.name ?? "Equipment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.showEditSetupSheet = true
                    } label: {
                        Text("Edit")
                    }
                }
                
                if viewModel.setups.count > 1 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            ForEach(viewModel.setups) { setup in
                                Button(action: { viewModel.activeSetupId = setup.id }) {
                                    HStack {
                                        Text(setup.name)
                                        if setup.id == viewModel.activeSetupId {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "list.bullet")
                        }
                    }
                }
                          
                ToolbarItem(placement: .topBarTrailing) {
                    Button { viewModel.showAddSetupSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .sheet(isPresented: $viewModel.showEditSightmarksSheet) {
                EditSightMarksView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showAddSetupSheet) {
                AddSetupView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showEditSetupSheet) {
                EditSetupView(viewModel: viewModel)
            }
            .contentMargins(.top, 0, for: .scrollContent)
        }
    }
}

struct AddSetupView: View {
    @Bindable var viewModel: EquipmentViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.fontResolutionContext) private var fontResolutionContext
    
    @State private var name: String = ""
    @State private var descriptionModel = RichTextEditorModel()
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Setup Details"), footer: Text("You can format the description using Markdown (e.g., **bold**, *italic*).")) {
                    TextField("Name (e.g. Indoor Bow)", text: $name)
                    TextEditor(text: $descriptionModel.text, selection: $descriptionModel.selection)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("New Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.createNewSetup(name: name, description: descriptionModel.text)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct EditSightMarksView: View {
    @Bindable var viewModel: EquipmentViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.sortedSightMarks) { sm in
                    HStack {
                        let distanceBinding = Binding<Double>(
                            get: {
                                let meters = viewModel.sightMarks.first(where: { $0.id == sm.id })?.distanceMeters ?? 0
                                return viewModel.displayDistance(meters)
                            },
                            set: { val in
                                let meters = viewModel.unitSystem == .metric ? val : val * 0.9144
                                if let idx = viewModel.sightMarks.firstIndex(where: { $0.id == sm.id }) {
                                    viewModel.sightMarks[idx].distanceMeters = meters
                                }
                            }
                        )

                        let sightBinding = Binding<Double>(
                            get: { viewModel.sightMarks.first(where: { $0.id == sm.id })?.sightValue ?? 0 },
                            set: { newVal in
                                if let idx = viewModel.sightMarks.firstIndex(where: { $0.id == sm.id }) {
                                    viewModel.sightMarks[idx].sightValue = newVal
                                }
                            }
                        )
                        
                        let extensionBinding = Binding<Int>(
                            get: { viewModel.sightMarks.first(where: { $0.id == sm.id })?.extensionValue ?? 0 },
                            set: { newVal in
                                if let idx = viewModel.sightMarks.firstIndex(where: { $0.id == sm.id }) {
                                    viewModel.sightMarks[idx].extensionValue = newVal
                                }
                            }
                        )

                        HStack {
                            TextField("0", value: distanceBinding, format: .number)
                                .keyboardType(.decimalPad)
                                .frame(width: 30)
                            Text(viewModel.unitSystem.distanceUnitLabel).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: 60)
                        .multilineTextAlignment(.trailing)

                        Spacer()

                        HStack {
                            Text("Elevation:").foregroundStyle(.secondary)
                            TextField("0.0", value: sightBinding, format: .number)
                                .keyboardType(.decimalPad)
                                .frame(width: 40)
                        }
                        .frame(maxWidth: 125)
                        
                        HStack {
                            Text("Extension:").foregroundStyle(.secondary)
                            TextField("0", value: extensionBinding, format: .number)
                                .keyboardType(.numberPad)
                                .frame(width: 25)
                        }
                        .frame(maxWidth: 115)
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            viewModel.deleteSightMark(id: sm.id)
                        }
                    }
                }
            }
            .navigationTitle("Edit Sight Marks")
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
    }
}

#Preview {
    EquipmentView()
}
