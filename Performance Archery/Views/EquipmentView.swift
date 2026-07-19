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
                    Button(action: { viewModel.showAddSetupSheet = true }) {
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
    
    @State private var drafts: [DraftSightMark] = []
    
    struct DraftSightMark: Identifiable {
        let id: UUID
        var distance: Double?
        var sightValue: Double?
        var extensionValue: Int?
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach($drafts) { $draft in
                    HStack {
                        HStack {
                            TextField("0", value: $draft.distance, format: .number)
                                .keyboardType(.decimalPad)
                                .frame(width: 30)
                            Text(viewModel.unitSystem.distanceUnitLabel).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: 60)
                        .multilineTextAlignment(.trailing)

                        Spacer()

                        HStack {
                            Text("Elevation:").foregroundStyle(.secondary)
                            TextField("0.0", value: $draft.sightValue, format: .number)
                                .keyboardType(.decimalPad)
                                .frame(width: 40)
                        }
                        .frame(maxWidth: 125)
                        
                        HStack {
                            Text("Extension:").foregroundStyle(.secondary)
                            TextField("0", value: $draft.extensionValue, format: .number)
                                .keyboardType(.numberPad)
                                .frame(width: 25)
                        }
                        .frame(maxWidth: 115)
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            drafts.removeAll(where: { $0.id == draft.id })
                        }
                    }
                }
            }
            .navigationTitle("Edit Sight Marks")
            .onAppear {
                drafts = viewModel.sortedSightMarks.map { sm in
                    DraftSightMark(
                        id: sm.id,
                        distance: viewModel.displayDistance(sm.distanceMeters),
                        sightValue: sm.sightValue,
                        extensionValue: sm.extensionValue
                    )
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                Button("Done") {
                    saveDrafts()
                    dismiss()
                }
            }
        }
    }
    
    private func saveDrafts() {
        var updatedMarks: [SightMark] = []
        
        for draft in drafts {
            let original = viewModel.sightMarks.first(where: { $0.id == draft.id })
            
            let fallbackDistance = original.map { viewModel.displayDistance($0.distanceMeters) } ?? 0
            let fallbackSight = original?.sightValue ?? 0
            let fallbackExtension = original?.extensionValue ?? 0
            
            let finalDistanceDisplay = draft.distance ?? fallbackDistance
            let finalSight = draft.sightValue ?? fallbackSight
            let finalExtension = draft.extensionValue ?? fallbackExtension
            
            let finalDistanceMeters = viewModel.unitSystem == .metric ? finalDistanceDisplay : finalDistanceDisplay * 0.9144
            
            let updatedMark = SightMark(
                id: draft.id,
                distanceMeters: finalDistanceMeters,
                sightValue: finalSight,
                extensionValue: finalExtension
            )
            
            updatedMarks.append(updatedMark)
        }
        
        viewModel.sightMarks = updatedMarks
    }
}

#Preview {
    EquipmentView()
}
