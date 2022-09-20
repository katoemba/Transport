//
//  CarrierInTransportAggregate.swift
//  
//
//  Created by Berrie Kremers on 20/09/2022.
//

import Foundation
import Configuration

public enum CarrierTransportHistory: Codable {
    case announced(timestamp: Date, destination: String)
    case inTransit(timestamp: Date, location: String)
    case delivered(timestamp: Date, location: String)
}

/// An aggregate that identifies a carrier that is either announced or in transit.
///
/// This aggregate is used as the payload for "TransportCommand", "CarrierSeenAtLocation" and "CarrierWithoutDestinationSeenAtLocation".
public class CarrierInTransportAggregate: Codable, Hashable, Comparable, Equatable {
    public init(type: CarrierType?, barcode: String, location: String? = nil, destination: String? = nil) {
        self.type = type
        self.barcode = barcode
        self.location = location
        self.destination = destination
    }
    
    /// The type of carrier that is being transported.
    public let type: CarrierType?
    /// The barcode that identifies the carrier.
    public let barcode: String
    /// The last location in the transport system where the carrier was seen. Empty if the carrier is not in transit yet.
    public var location: String?
    /// The destination of the carrier. Empty if the destination is unknown.
    public var destination: String?
    /// A locations in the transport system where the carrier was seen. The history is omitted in the payload of events.
    var history = [CarrierTransportHistory]()
    
    private enum CodingKeys: String, CodingKey {
        case type, barcode, location, destination
    }

    /// Carrier aggregates are treated as equal when the have the same barcode.
    public static func == (lhs: CarrierInTransportAggregate, rhs: CarrierInTransportAggregate) -> Bool {
        lhs.barcode == rhs.barcode
    }

    /// Define the sort order of carrier aggregates. The barcode is used as sort criteria.
    public static func < (lhs: CarrierInTransportAggregate, rhs: CarrierInTransportAggregate) -> Bool {
        lhs.barcode < rhs.barcode
    }
    
    public func hash(into hasher: inout Hasher) {
        barcode.hash(into: &hasher)
    }
}
