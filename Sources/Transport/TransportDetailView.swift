//
//  TransportDetailView.swift
//  Inbound
//
//  Created by Berrie Kremers on 08/09/2022.
//

import SwiftUI

struct TransportDetailView: View {
    var carrierInTransport: Transport.CarrierInTransportAggregate
    let dateFormatter: DateFormatter
    
    init(carrierInTransport: Transport.CarrierInTransportAggregate) {
        self.carrierInTransport = carrierInTransport
        
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'  'HH:mm:ss.SSS"
    }
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 15) {
                Text("CarrierInTransport Aggregate")
                    .font(.largeTitle)

                HStack {
                    Text("Status")
                        .fontWeight(.bold)
                    Text(carrierInTransport.history.last?.description ?? "Missing")
                }

                HStack {
                    Text("Type")
                        .fontWeight(.bold)
                    Text(carrierInTransport.type?.rawValue ?? "Missing")
                }

                HStack {
                    Text("Barcode")
                        .fontWeight(.bold)
                    Text(carrierInTransport.barcode)
                }
                
                HStack {
                    Text("Location")
                        .fontWeight(.bold)
                    Text(carrierInTransport.location ?? "Missing")
                }

                HStack {
                    Text("Destination")
                        .fontWeight(.bold)
                    Text(carrierInTransport.destination ?? "Missing")
                }

                VStack(alignment: .leading) {
                    Text("History")
                        .fontWeight(.bold)

                    ForEach(Array(carrierInTransport.history.enumerated()), id: \.offset) { _, history in
                            switch history {
                            case let .announced(timestamp: timestamp, destination: destination):
                                HStack {
                                    Text("Announced - ")

                                    Text("Timestamp:")
                                    Text(timestamp, formatter: dateFormatter)
                                    
                                    Text("Destination:")
                                    Text(destination)
                                }
                            case let .inTransit(timestamp: timestamp, location: location):
                                HStack {
                                    Text("In Transport - ")

                                    Text("Timestamp:")
                                    Text(timestamp, formatter: dateFormatter)

                                    Text("Location:")
                                    Text(location)
                                }
                            case let .delivered(timestamp: timestamp, location: location):
                                HStack {
                                    Text("Delivered - ")

                                    Text("Timestamp:")
                                    Text(timestamp, formatter: dateFormatter)

                                    Text("Location:")
                                    Text(location)
                                }
                            }
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle(carrierInTransport.barcode)
            
            Spacer()
        }
    }
}

extension Transport.CarrierTransportHistory {
    var description: String {
        switch self {
        case .announced(_, _):
            return "Announced"
        case .inTransit(_, _):
            return "In Transit"
        case .delivered(_, _):
            return "Delivered"
        }
    }
}

//struct TransportDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        TransportDetailView()
//    }
//}
