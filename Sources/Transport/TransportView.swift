//
//  TransportView.swift
//  Inbound
//
//  Created by Berrie Kremers on 08/09/2022.
//

import SwiftUI
import EventManager
import Configuration

public struct TransportView: View {
    struct BarcodeAtLocation: Codable {
        let barcode: String
        let location: String
    }
    @ObservedObject var transportManager = Transport.shared
    @State var barcodeAtLocation = false
    @State var transportCommand = false
    @State var barcode = ""
    @State var location = ""
    @State var destination = ""
    @State var selectedCarrier: CarrierInTransportAggregate? = nil
    
    public init() {
    }
    
    public var body: some View {
        List {
            Section(header: Text("Announced")) {
                ForEach(transportManager.carriersInTransport.filter({ $1.location == nil }).sorted(by: <), id: \.key) { key, carrierInTransport in
                    NavigationLink(destination: TransportDetailView(carrierInTransport: carrierInTransport), tag: carrierInTransport, selection: $selectedCarrier) {
                        Label(carrierInTransport.barcode, systemImage: "shippingbox")
                    }
                }
            }
            
            Section(header: Text("In transit")) {
                ForEach(transportManager.carriersInTransport.filter({ $1.location != nil &&  $1.location != $1.destination }).sorted(by: <), id: \.key) { key, carrierInTransport in
                    NavigationLink(destination: TransportDetailView(carrierInTransport: carrierInTransport), tag: carrierInTransport, selection: $selectedCarrier) {
                        Label(carrierInTransport.barcode, systemImage: "shippingbox")
                    }
                }
            }

            Section(header: Text("Delivered")) {
                ForEach(transportManager.carriersInTransport.filter({ $1.location == $1.destination }).sorted(by: <), id: \.key) { key, carrierInTransport in
                    NavigationLink(destination: TransportDetailView(carrierInTransport: carrierInTransport), tag: carrierInTransport, selection: $selectedCarrier) {
                        Label(carrierInTransport.barcode, systemImage: "shippingbox")
                    }
                }
            }
        }
#if os(macOS)
        .frame(width: 300)
#endif
        .navigationTitle("Transports")
        .toolbar {
#if os(macOS)
            ToolbarItem(placement: .automatic) {
                Button {
                    showTrackingAlert()
                } label: {
                    Label("PLC Tracking", systemImage: "barcode.viewfinder")
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Button {
                    showTransportCommand()
                } label: {
                    Label("Transport Command", systemImage: "plus.circle")
                }
            }
#else
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showTrackingAlert()
                } label: {
                    Label("PLC Tracking", systemImage: "barcode.viewfinder")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showTransportCommand()
                } label: {
                    Label("Transport Command", systemImage: "plus.circle")
                }
            }
#endif
        }
        .sheet(isPresented: $barcodeAtLocation) {
#if os(macOS)
            TrackingAlertView(barcode: $barcode, location: $location, barcodeAtLocation: $barcodeAtLocation)
                .frame(width: 300, height: 140)
#else
            NavigationView() {
                TrackingAlertView(barcode: $barcode, location: $location, barcodeAtLocation: $barcodeAtLocation)
                    .navigationTitle("Carrier at Location")
            }
#endif
        }
        .sheet(isPresented: $transportCommand) {
#if os(macOS)
            TransportCommandView(barcode: $barcode, destination: $destination, transportCommand: $transportCommand)
                .frame(width: 300, height: 140)
#else
            NavigationView() {
                TransportCommandView(barcode: $barcode, destination: $destination, transportCommand: $transportCommand)
                    .navigationTitle("Transport Command")
            }
#endif
        }
    }
    
    func showTrackingAlert() {
        barcode = selectedCarrier?.barcode ?? ""
        location = ""
        barcodeAtLocation = true
    }
    
    func showTransportCommand() {
        barcode = ""
        destination = ""
        transportCommand = true
    }
}

struct TransportView_Previews: PreviewProvider {
    static var previews: some View {
        TransportView()
    }
}

struct TrackingAlertView: View {
    @Binding var barcode: String
    @Binding var location: String
    @Binding var barcodeAtLocation: Bool
    
    public var body: some View {
        Form {
            TextField("barcode", text: $barcode)
            Picker(selection: $location, label: Text("location")) {
                ForEach(Configuration.locations) {
                    Text($0.name).tag($0.name)
                }
            }
            .fixedSize()
            
#if os(macOS)
            HStack {
                Spacer()
                
                Button {
                    barcodeAtLocation = false
                } label: {
                    Text("Cancel")
                }
                .keyboardShortcut(.cancelAction)
                
                Button {
                    EventManager.shared.publish("BarcodeAtLocation", sender: "PLC", object: TransportView.BarcodeAtLocation(barcode: barcode, location: location))
                    barcodeAtLocation = false
                } label: {
                    Text("Ok")
                }
                .keyboardShortcut(.defaultAction)
            }
#endif
        }
#if os(iOS)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    EventManager.shared.publish("BarcodeAtLocation", sender: "PLC", object: TransportView.BarcodeAtLocation(barcode: barcode, location: location))
                    barcodeAtLocation = false
                } label: {
                    Text("Ok")
                }
            }
        }
#else
        .padding()
        .frame(width: 300, height: 140)
#endif
    }
}

struct TransportCommandView: View {
    @Binding var barcode: String
    @Binding var destination: String
    @Binding var transportCommand: Bool
    
    public var body: some View {
        Form {
            TextField("barcode", text: $barcode)
            Picker(selection: $destination, label: Text("destination")) {
                ForEach(Configuration.exits + Configuration.workStations) {
                    Text($0.name).tag($0.name)
                }
            }
            .fixedSize()
            
#if os(macOS)
            HStack {
                Spacer()
                
                Button {
                    transportCommand = false
                } label: {
                    Text("Cancel")
                }
                .keyboardShortcut(.cancelAction)
                
                Button {
                    EventManager.shared.publish("TransportCommand", sender: "Mock", object: CarrierInTransportAggregate(type: .pallet, barcode: barcode, location: nil, destination: destination))
                    transportCommand = false
                } label: {
                    Text("Ok")
                }
                .keyboardShortcut(.defaultAction)
            }
#endif
        }
#if os(iOS)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    EventManager.shared.publish("TransportCommand", sender: "Mock", object: Transport.CarrierInTransportAggregate(type: .pallet, barcode: barcode, location: nil, destination: destination))
                    transportCommand = false
                } label: {
                    Text("Ok")
                }
            }
        }
#else
        .padding()
        .frame(width: 300, height: 140)
#endif
    }
}
