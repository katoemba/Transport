import Foundation
import EventManager
import Configuration

public class Transport: ObservableObject {
    private let sender = "Transport"
    
    public struct BarcodeAtLocation: Codable {
        public init(barcode: String, location: String) {
            self.barcode = barcode
            self.location = location
        }
        
        public let barcode: String
        public let location: String
    }
    
    @Published var carriersInTransport = [String: CarrierInTransportAggregate]()
    
    // MARK: Initialization
    
    public static let shared = Transport()
    private init() {
        registerForEvents()
    }
    
    func registerForEvents() {
        // Listen to the PLC
        _ = EventManager.shared.subscribe("BarcodeAtLocation") { [weak self] (name: String, barcodeAtLocation: BarcodeAtLocation) in
            guard let weakSelf = self else { return }
            weakSelf.barcodeAtLocation(barcodeAtLocation.barcode, at: barcodeAtLocation.location)
        }
        
        // Listen to transport command
        _ = EventManager.shared.subscribe("TransportCommand") { [weak self] (name: String, carrierToTransport: CarrierInTransportAggregate) in
            guard let weakSelf = self else { return }
            weakSelf.transportCommand(carrier: carrierToTransport)
        }
    }

    // MARK: Event handlers
    
    /// Process a tracking update received from the PLC. This will publish a CarrierSeenAtLocation event containing a ``CarrierInTransportAggregate``.
    /// In case the carrier has reached it's destination, it will be marked as 'delivered'.
    /// - Parameters:
    ///    - barcode: The barcode that identifies the carrier that is tracked.
    ///    - location: The location where the carrier is seen.
    public func barcodeAtLocation(_ barcode: String, at location: String) {
        let carrierInTransport = carriersInTransport[barcode] ?? CarrierInTransportAggregate(type: nil, barcode: barcode, location: location)
                
        carrierInTransport.location = location
        carriersInTransport[barcode] = carrierInTransport
        
        if carrierInTransport.destination == nil {
            EventManager.shared.publish("CarrierWithoutDestinationSeenAtLocation", sender: sender, object: carrierInTransport)
        }
        else {
            EventManager.shared.publish("CarrierSeenAtLocation", sender: sender, object: carrierInTransport)
        }
        carrierInTransport.history.append(.inTransit(timestamp: Date(), location: location))

        if carrierInTransport.location != nil && carrierInTransport.destination == carrierInTransport.location {
            carrierInTransport.history.append(.delivered(timestamp: Date(), location: location))
        }
    }
    
    // MARK: Commands

    func transportCommand(carrier: CarrierInTransportAggregate) {
        if let carrierInTransport = carriersInTransport[carrier.barcode] {
            let updatedCarrier = carrier
            updatedCarrier.location = carrierInTransport.location
            carriersInTransport[updatedCarrier.barcode] = updatedCarrier
        }
        else {
            carriersInTransport[carrier.barcode] = carrier
            carrier.history.append(.announced(timestamp: Date(), destination: carrier.destination!))
        }
    }
}
