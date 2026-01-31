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
                        
                        HStack {
                            HStack {
                                TextField("0", value: $viewModel.inputDistance, format: .number)
                                    .keyboardType(.decimalPad)
                                Text(viewModel.unitSystem.distanceUnitLabel).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: 60)
                            .multilineTextAlignment(.trailing)
                            
                            Spacer()
                            
                            HStack {
                                Text("Elevation:").foregroundStyle(.secondary)
                                TextField("0.0", value: $viewModel.inputSightValue, format: .number)
                                    .keyboardType(.decimalPad)
                            }
                            .frame(maxWidth: 160)
                            
                            Button("Add") { viewModel.addSightMark() }
                                .buttonStyle(.borderedProminent)
                                .disabled(!viewModel.canAddSightMark)
                        }
                    }
                }
            }
            .navigationTitle("Equipment")
            .scrollDismissesKeyboard(.interactively)
            .sheet(isPresented: $viewModel.showEditSightmarksSheet) {
                EditSightMarksView(viewModel: viewModel)
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
                        let distBinding = Binding<Double>(
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

                        HStack {
                            TextField("0", value: distBinding, format: .number)
                                .keyboardType(.decimalPad)
                            Text(viewModel.unitSystem.distanceUnitLabel).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: 60)
                        .multilineTextAlignment(.trailing)

                        Spacer()

                        HStack {
                            Text("Elevation:").foregroundStyle(.secondary)
                            TextField("0.0", value: sightBinding, format: .number)
                                .keyboardType(.decimalPad)
                        }
                        .frame(maxWidth: 250)
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
