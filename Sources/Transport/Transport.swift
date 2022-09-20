import Foundation
import EventManager
import Configuration

public class Transport: ObservableObject {
    private let sender = "Transport"
    public class CarrierInTransportAggregate: Codable, Hashable, Comparable, Equatable {
        public init(type: CarrierType?, barcode: String, location: String? = nil, destination: String? = nil) {
            self.type = type
            self.barcode = barcode
            self.location = location
            self.destination = destination
        }
        
        public static func == (lhs: Transport.CarrierInTransportAggregate, rhs: Transport.CarrierInTransportAggregate) -> Bool {
            lhs.barcode == rhs.barcode
        }

        public static func < (lhs: Transport.CarrierInTransportAggregate, rhs: Transport.CarrierInTransportAggregate) -> Bool {
            lhs.barcode < rhs.barcode
        }
        
        public func hash(into hasher: inout Hasher) {
            barcode.hash(into: &hasher)
        }
        
        public let type: CarrierType?
        public let barcode: String
        public var location: String?
        public var destination: String?
        public var history = [CarrierTransportHistory]()
        
        private enum CodingKeys: String, CodingKey {
            case type, barcode, location, destination
        }
    }
    public struct BarcodeAtLocation: Codable {
        public init(barcode: String, location: String) {
            self.barcode = barcode
            self.location = location
        }
        
        public let barcode: String
        public let location: String
    }
    
    public enum CarrierTransportHistory: Codable {
        case announced(timestamp: Date, destination: String)
        case inTransit(timestamp: Date, location: String)
        case delivered(timestamp: Date, location: String)
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
            weakSelf.handle(barcode: barcodeAtLocation.barcode, at: barcodeAtLocation.location)
        }
        
        // Listen to transport command
        _ = EventManager.shared.subscribe("TransportCommand") { [weak self] (name: String, carrierToTransport: CarrierInTransportAggregate) in
            guard let weakSelf = self else { return }
            weakSelf.transportCommand(carrier: carrierToTransport)
        }
    }

    // MARK: Event handlers
    
    func handle(barcode: String, at location: String) {
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
