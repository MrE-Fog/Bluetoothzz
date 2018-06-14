//
//  LowEnergyEventParameter.swift
//  Bluetooth
//
//  Created by Alsey Coleman Miller on 3/2/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import Foundation

public extension LowEnergyEvent {
    
    /// LE Read Local P-256 Public Key Complete Event
    ///
    /// This event is generated when local P-256 key generation is complete.
    public struct ReadLocalP256PublicKeyCompleteEventParameter: HCIEventParameter {
        
        public static let event = LowEnergyEvent.readLocalP256PublicKeyComplete // 0x08
        
        public static let length: Int = 65
        
         public let status: HCIStatus
        
        public let localP256PublicKey: UInt512
        
        public init?(data: Data) {
            
            guard data.count == type(of: self).length
                else { return nil }
            
            let statusByte = data[0]
            
            guard let status = HCIStatus(rawValue: statusByte)
                else { return nil }
            
            let localP256PublicKey = UInt512(littleEndian: UInt512(bytes: ((data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8], data[9], data[10], data[11], data[12], data[13], data[14], data[15], data[16], data[17], data[18], data[19], data[20], data[21], data[22], data[23], data[24], data[25], data[26], data[27], data[28], data[29], data[30], data[31], data[32], data[33], data[34], data[35], data[36], data[37], data[38], data[39], data[40], data[41], data[42], data[43], data[44], data[45], data[46], data[47], data[48], data[49], data[50], data[51], data[52], data[53], data[54], data[55], data[56], data[57], data[58], data[59], data[60], data[61], data[62], data[63], data[64]))))
            
            self.status = status
            self.localP256PublicKey = localP256PublicKey
        }
    }
    
    /// LE Generate DHKey Complete Event
    ///
    /// This event indicates that LE Diffie Hellman key generation has been completed by the Controller.
    public struct GenerateDHKeyCompleteEventParameter: HCIEventParameter {
        
        public static let event = LowEnergyEvent.generateDHKeyComplete // 0x09
        
        public static let length: Int = 33
        
        public let status: HCIStatus
        
        public let dhKey: UInt256
        
        public init?(data: Data) {
            
            guard data.count == type(of: self).length
                else { return nil }
            
            let statusByte = data[0]
            
            guard let status = HCIStatus(rawValue: statusByte)
                else { return nil }
            
            let dhKey = UInt256(littleEndian: UInt256(bytes: ((data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8], data[9], data[10], data[11], data[12], data[13], data[14], data[15], data[16], data[17], data[18], data[19], data[20], data[21], data[22], data[23], data[24], data[25], data[26], data[27], data[28], data[29], data[30], data[31], data[32]))))
            
            self.status = status
            self.dhKey = dhKey
        }
    }
    
    /// LE Enhanced Connection Complete Event
    ///
    /// The event indicates to both of the Hosts forming the connection that a new connection has been created.
    public struct EnhancedConnectionCompleteEventParameter: HCIEventParameter {
        
        public static let event = LowEnergyEvent.enhancedConnectionComplete // 0x0A
        
        public static let length: Int = 30
        
        public let status: HCIStatus
        
        public let connectionHandle: UInt16
        
        public let role: LowEnergyRole
        
        /// Peer Bluetooth address type.
        public let peerAddressType: LowEnergyAddressType // Peer_Address_Type
        
        /// Public Device Address, or Random Device Address, Public Identity Address or
        /// Random (static) Identity Address of the device to be con- nected.
        public let peerAddress: Address
        
        /// Resolvable Private Address being used by the local device for this connection.
        /// This is only valid when the Own_Address_Type (from the HCI_LE_Create_Connection,
        /// HCI_LE_Set_Advertising_Parameters, HCI_LE_Set_Extended_Advertising_Parameters, or
        /// HCI_LE_Extended_Create_Connection commands) is set to 0x02 or 0x03, and the Controller
        /// generated a resolvable private address for the local device using a non-zero local IRK.
        /// For other Own_Address_Type values, the Controller shall return all zeros.
        public let localResolvablePrivateAddress: Address
        
        /// Resolvable Private Address being used by the peer device for this con- nection.
        /// This is only valid for Peer_Address_Type 0x02 and 0x03. For other Peer_Address_Type
        /// values, the Controller shall return all zeros.
        public let peerResolvablePrivateAddress: Address
        
        /// Connection interval used on this connection.
        ///
        /// Range: 0x0006 to 0x0C80
        /// Time = N * 1.25 msec
        /// Time Range: 7.5 msec to 4000 msec.
        public let interval: LowEnergyConnectionInterval
        
        /// Slave latency for the connection in number of connection events.
        /// Range: 0x0000 to 0x01F3
        public let latency: LowEnergyConnectionLatency
        
        /// Connection supervision timeout. Range: 0x000A to 0x0C80
        /// Time = N * 10 ms
        /// Time Range: 100 ms to 32 s
        public let supervisionTimeout: LowEnergySupervisionTimeout
        
        public let masterClockAccuracy: LowEnergyClockAccuracy
        
        public init?(data: Data) {
            guard data.count == type(of: self).length
                else { return nil }
            
            guard let status = HCIStatus(rawValue: data[0])
                else { return nil }
            
            let handle = UInt16(littleEndian: UInt16(bytes: (data[1], data[2])))
            
            guard let role = LowEnergyRole(rawValue: data[3])
                else { return nil }
            
            guard let peerAddressType = LowEnergyAddressType(rawValue: data[4])
                else { return nil }
            
            let peerAddress = Address(littleEndian: Address(bytes: (data[5],
                                                                    data[6], data[7],
                                                                    data[8], data[9],
                                                                    data[10])))
            
            let localResolvableprivateAddress = Address(littleEndian: Address(bytes: (data[11],
                                                                                      data[12], data[13],
                                                                                      data[14], data[15],
                                                                                      data[16])))
            
            let peerResolvablePrivateAddress = Address(littleEndian: Address(bytes: (data[17],
                                                                                     data[18], data[19],
                                                                                     data[20], data[21],
                                                                                     data[22])))
            
            let connInternal = LowEnergyConnectionInterval(rawValue: UInt16(littleEndian: UInt16(bytes: (data[23], data[24]))))
            
            guard let latency = LowEnergyConnectionLatency(rawValue: UInt16(littleEndian: UInt16(bytes: (data[25], data[26]))))
                else { return nil }
            
            guard let supervisionTimeout = LowEnergySupervisionTimeout(rawValue: UInt16(littleEndian: UInt16(bytes: (data[27], data[28]))))
                else { return nil }
            
            guard let masterClockAccuracy = LowEnergyClockAccuracy(rawValue: data[29])
                else { return nil }
            
            self.status = status
            self.connectionHandle = handle
            self.role = role
            self.peerAddressType = peerAddressType
            self.peerAddress = peerAddress
            self.localResolvablePrivateAddress = localResolvableprivateAddress
            self.peerResolvablePrivateAddress = peerResolvablePrivateAddress
            self.interval = connInternal
            self.latency = latency
            self.supervisionTimeout = supervisionTimeout
            self.masterClockAccuracy = masterClockAccuracy
        }
    }
    
    /// LE Directed Advertising Report Event
    ///
    /// The event indicates that directed advertisements have been received where the advertiser
    /// is using a resolvable private address for the TargetA field of the advertising PDU which
    /// the Controller is unable to resolve and the Scanning_Filter_Policy is equal to 0x02 or 0x03.
    public struct DirectedAdvertisingReportEventParameter: HCIEventParameter {
        
        public static let event = LowEnergyEvent.directedAdvertisingReport // 0x0B
        
        public static let length = 1 + Report.length // must have at least one report
        
        public let reports: [Report]
        
        public init?(data: Data) {
            
            guard data.count >= type(of: self).length
                else { return nil }
            
            // Number of responses in event.
            let reportCount = Int(data[0]) // Num_Reports
            
            // 0x01 - 0x19
            guard reportCount > 0,
                reportCount <= 25
                else { return nil }
            
            var reports = [Report]()
            reports.reserveCapacity(reportCount)
            
            var offset = 1
            for _ in 0 ..< reportCount {
                
                let reportBytes = Data(data.suffix(from: offset))
                
                guard let report = Report(data: reportBytes)
                    else { return nil }
                
                offset += Report.length
                reports.append(report)
            }
            
            self.reports = reports
        }
        
        public struct Report {
            
            public static let length = 1 + 1 + 6 + 1 + 6 + 1
            
            public let event: UInt8
            
            public let addressType: AddressType // Address_Type
            
            /// Public Device Address, Random Device Address, Public Identity Address or
            /// Random (static) Identity Address of the advertising device.
            public let address: Address // Address
            
            public let directAddressType: UInt8
            
            /// Random Device Address
            public let directAddress: Address // Direct_Address
            
            /// RSSI
            ///
            /// Size: 1 Octet (signed integer)
            /// Range: -127 ≤ N ≤ +20
            /// Units: dBm
            public let rssi: RSSI // RSSI
            
            public init?(data: Data) {
                
                guard data.count >= Report.length
                    else { return nil }
                
                // parse enums
                let event = data[0]
                
                guard let addressType = AddressType(rawValue: data[1])
                    else { return nil }
                
                let address = Address(littleEndian:
                    Address(bytes: (data[2],
                                    data[3],
                                    data[4],
                                    data[5],
                                    data[6],
                                    data[7])))
                
                let directAddressType = data[8]
                
                let directAddress = Address(littleEndian:
                    Address(bytes: (data[9],
                                    data[10],
                                    data[11],
                                    data[12],
                                    data[13],
                                    data[14])))
    
                let rssiByte = Int8(bitPattern: data[15])
                
                guard let rssi = RSSI(rawValue: rssiByte)
                    else { return nil }
                
                self.event = event
                self.addressType = addressType
                self.address = address
                self.directAddressType = directAddressType
                self.directAddress = directAddress
                self.rssi = rssi
            }
        }
        
        public enum AddressType: UInt8 {
            
            /// Public Device Address (default)
            case publicDeviceAddress        = 0x00
            
            /// Random Device Address
            case randomDeviceAddress        = 0x01
            
            /// Public Identity Address (Corresponds to Resolved Private Address )
            case publicIdentityAddress      = 0x02
            
            /// Random (static) Identity Address (Corresponds to Resolved Private Address)
            case randomIdentyAddress        = 0x03
            
            /// No address provided (anonymous advertisement)
            case noAddressProvided          = 0xFF
        }
    }
    
    /// LE PHY Update Complete Event
    ///
    /// The LE PHY Update Complete Event is used to indicate that the Controller has changed
    /// the transmitter PHY or receiver PHY in use.
    ///
    /// If the Controller changes the transmitter PHY, the receiver PHY, or both PHYs,
    /// this event shall be issued.
    ///
    /// If an LE_Set_PHY command was sent and the Controller determines that neither PHY will
    /// change as a result, it issues this event immediately.
    public struct PhyUpdateCompleteEventParameter: HCIEventParameter {
        
        public static let event = LowEnergyEvent.phyUpdateComplete // 0x0C
        
        public static let length: Int = 5
        
        public let status: HCIStatus
        
        public let handle: UInt16 // Connection_Handle
        
        public let txPhy: LowEnergyTxPhy
        
        public let rxPhy: LowEnergyRxPhy
        
        public init?(data: Data) {
            
            guard data.count == type(of: self).length
                else { return nil }
            
            let statusByte = data[0]
            
            let handle = UInt16(littleEndian: UInt16(bytes: (data[1], data[2])))
            
            guard let status = HCIStatus(rawValue: statusByte)
                else { return nil }
            
            guard let txPhy = LowEnergyTxPhy(rawValue: data[3])
                else { return nil }
            
            guard let rxPhy = LowEnergyRxPhy(rawValue: data[4])
                else { return nil }
            
            self.status = status
            self.handle = handle
            self.txPhy = txPhy
            self.rxPhy = rxPhy
        }
    }
    
    /// LE Extended Advertising Report Event
    ///
    /// The event indicates that one or more Bluetooth devices have responded to an active scan
    /// or have broadcast advertisements that were received during a passive scan.
    /// The Controller may coalesce multiple advertising reports from the same or different advertisers
    /// into a single LE Extended Advertising Report event, provided all the parameters from all the advertising reports
    /// fit in a single HCI event.
    public struct ExtendedAdvertisingReportEventParameter: HCIEventParameter {
        
        public static let event = LowEnergyEvent.extendedAdvertisingReport // 0x0D
        
        public static let length = 1 + Report.length // must have at least one report
        
        public let reports: [Report]
        
        public init?(data: Data) {
            
            guard data.count >= type(of: self).length
                else { return nil }
            
            // Number of responses in event.
            let reportCount = Int(data[0]) // Num_Reports
            
            // 0x01 - 0x0A
            guard reportCount > 0,
                reportCount <= 10
                else { return nil }
            
            var reports = [Report]()
            reports.reserveCapacity(reportCount)
            
            var offset = 1
            for _ in 0 ..< reportCount {
                
                let reportBytes = Data(data.suffix(from: offset))
                
                guard let report = Report(data: reportBytes)
                    else { return nil }
                
                offset += Report.length + report.responseData.count
                reports.append(report)
            }
            
            self.reports = reports
        }
        
        public struct Report {
            
            public static let length = 2 + 1 + 6 + 1 + 1 + 1 + 1 + 1 + 2 + 1 + 6 + 1
        
            public let eventType: EventType
            
            public let addressType: AddressType
            
            public let address: Address
            
            public let primaryPHY: PrimaryPHY
            
            public let secondaryPHY: SecondaryPHY
            
            public let advertisingSID: UInt8
            
            public let txPower: LowEnergyTxPower
            
            public let rssi: RSSI
            
            public let periodicAdvertisingInterval: PeriodicAdvertisingInterval
            
            public let directAddressType: AddressType
            
            public let directAddress: Address
            
            public let responseData: Data //Data
            
            public init?(data: Data) {
                
                guard data.count >= Report.length
                    else { return nil }
                
                guard let eventType = EventType(rawValue: UInt16(bytes: (data[0], data[1]))),
                    let addressType = AddressType(rawValue: data[2])
                    else { return nil }
                
                let address = Address(littleEndian: Address(bytes: (data[3], data[4],
                                    data[5], data[6],
                                    data[7], data[8])))
                
                guard let primaryPHY = PrimaryPHY(rawValue: data[9]),
                    let secondaryPHY = SecondaryPHY(rawValue: data[10])
                    else { return nil }
                
                let advertisingSID = data[11]
                
                let txPowerByte = Int8(bitPattern: data[12])
                
                guard let txPower = LowEnergyTxPower(rawValue: txPowerByte)
                    else { return nil }
                
                let rssiByte = Int8(bitPattern: data[13])
                
                guard let rssi = RSSI(rawValue: rssiByte)
                    else { return nil }
                
                let periodicAdvertisingInterval = PeriodicAdvertisingInterval(rawValue: UInt16(bytes: (data[14], data[15])))
                
                guard let directAddressType = AddressType(rawValue: data[16])
                    else { return nil }
                
                let directAddress = Address(littleEndian: Address(bytes: (data[17], data[18],
                                    data[19], data[20],
                                    data[21], data[22])))
                
                let dataLength = Int(data[23])
                
                let data = Data(data[24 ..< (24 + dataLength)])
                assert(data.count == dataLength)
                
                self.eventType = eventType
                self.addressType = addressType
                self.address = address
                self.primaryPHY = primaryPHY
                self.secondaryPHY = secondaryPHY
                self.advertisingSID = advertisingSID
                self.txPower = txPower
                self.rssi = rssi
                self.periodicAdvertisingInterval = periodicAdvertisingInterval
                self.directAddressType = directAddressType
                self.directAddress = directAddress
                self.responseData = data
            }
        }
        
        /// nterval of the periodic advertising
        /// Range: 0x0006 to 0xFFFF
        /// Time = N * 1.25 ms
        /// Time Range: 7.5 ms to 81,918.75 s
        public struct PeriodicAdvertisingInterval: RawRepresentable, Equatable, Hashable, Comparable {
            
            /// 7.5 msec
            public static let min = PeriodicAdvertisingInterval(0x0006)
            
            /// 81,918.75 sec
            public static let max = PeriodicAdvertisingInterval(0xFFFF)
            
            public let rawValue: UInt16
            
            public init(rawValue: UInt16) {
                
                self.rawValue = rawValue
            }
            
            /// Time = N * 1.25 msec
            public var miliseconds: Double {
                
                return Double(rawValue) * 1.25
            }
            
            // Private, unsafe
            private init(_ rawValue: UInt16) {
                self.rawValue = rawValue
            }
            
            // Equatable
            public static func == (lhs: PeriodicAdvertisingInterval, rhs: PeriodicAdvertisingInterval) -> Bool {
                
                return lhs.rawValue == rhs.rawValue
            }
            
            // Comparable
            public static func < (lhs: PeriodicAdvertisingInterval, rhs: PeriodicAdvertisingInterval) -> Bool {
                
                return lhs.rawValue < rhs.rawValue
            }
            
            // Hashable
            public var hashValue: Int {
                
                return Int(rawValue)
            }
        }
        
        /// Secondary_PHY
        public enum SecondaryPHY: UInt8 {
            
            /// No packets on the secondary advertising channel
            case noPackets  = 0x00
            
            /// Advertiser PHY is LE 1M
            case le1M       = 0x01
            
            /// Advertiser PHY is LE 2M
            case let2M      = 0x02
            
            /// Advertiser PHY is LE Coded
            case coded      = 0x03
        }
        
        /// Primary_PHY
        public enum PrimaryPHY: UInt8 {
            
            /// Advertiser PHY is LE 1M
            case le1M       = 0x01
            
            /// Advertiser PHY is LE Coded
            case coded      = 0x03
        }
        
        /// Address_Type
        public enum AddressType: UInt8 {
            
            /// Public Device Address (default)
            case publicDeviceAddress        = 0x00
            
            /// Random Device Address
            case randomDeviceAddress        = 0x01
            
            /// Public Identity Address (Corresponds to Resolved Private Address )
            case publicIdentityAddress      = 0x02
            
            /// Random (static) Identity Address (Corresponds to Resolved Private Address)
            case randomIdentyAddress        = 0x03
            
            /// No address provided (anonymous advertisement)
            case noAddressProvided          = 0xFF
        }
        
        /// Event Type
        public enum EventType: UInt16, BitMaskOption {
            
            #if swift(>=3.2)
            #elseif swift(>=3.0)
            public typealias RawValue = UInt16
            #endif
            
            /// Connectable advertising
            case connectableAdvertising         = 0b0000000000000001
            
            /// Scannable advertising
            case scannableAdvertising           = 0b0000000000000010
            
            /// Directed advertising
            case directedAdvertising            = 0b0000000000000100
            
            /// Scan response
            case scanResponse                   = 0b0000000000001000
            
            /// Legacy advertising PDUs used
            case legacyAdvertisingPDU           = 0b0000000000010000
            
            /// Data status: Complete
            case dataStatusComplete             = 0b0000000000000000
            
            /// Data status: Incomplete, more data to come
            case dataStatusIncompleteMoreData   = 0b0000000000100000
            
            /// Data status: Incomplete, data truncated, no more to come
            case dataStatusIncompleteTruncated  = 0b0000000001000000
            
            /// Data status: Reserved for future use
            case dataStatusReserved             = 0b0000000001100000
            
            /// All enum cases
            public static let all: Set<EventType> = [
                .connectableAdvertising,
                .scannableAdvertising,
                .directedAdvertising,
                .scanResponse,
                .legacyAdvertisingPDU,
                .dataStatusComplete,
                .dataStatusIncompleteMoreData,
                .dataStatusIncompleteTruncated,
                .dataStatusReserved
            ]
        }
    }
    
    /// LE Periodic Advertising Sync Established Event
    ///
    /// The event indicates that the Controller has received the first periodic advertising packet from an advertiser
    /// after the LE_Periodic_Advertising_Create_Sync Command has been sent to the Controller.
    ///
    /// The Sync_Handle shall be assigned by the Controller.
    ///
    /// This event indicates to the Host which issued an LE_Periodic_Advertising_Create_Sync command and received a
    /// Command Status event if the periodic advertising reception failed or was successful.
    public struct PeriodicAdvertisingSyncEstablishedEventParameter: HCIEventParameter {
        
        public static let event = LowEnergyEvent.periodicAdvertisingSyncEstablished // 0x0E
        
        public static let length = 15
        
        public let status: HCIStatus
        
        /// Sync_Handle to be used to identify the periodic advertiser
        /// Range: 0x0000-0x0EFF
        public let syncHandle: UInt16 // Sync_Handle
        
        /// Value of the Advertising SID subfield in the ADI field of the PDU
        public let advertisingSID: UInt8
        
        public let advertiserAddressType: LowEnergyAddressType
        
        public let advertiserAddress: Address
        
        public let advertiserPHY: AdvertiserPhy
        
        public let periodicAdvertisingInterval: PeriodicAdvertisingInterval
        
        public let advertiserClockAccuracy: LowEnergyClockAccuracy
        
        public init?(data: Data) {
            
            guard data.count == type(of: self).length
                else { return nil }
            
            guard let status = HCIStatus(rawValue: data[0])
                else { return nil }
            
            let syncHandle = UInt16(littleEndian: UInt16(bytes: (data[1], data[2])))
            
            let advertisingSID = data[3]
            
            guard let advertiserAddressType = LowEnergyAddressType(rawValue: data[4])
                else { return nil }
            
            let advertiserAddress = Address(littleEndian: Address(bytes: (data[5], data[6], data[7], data[8], data[9], data[10])))
            
            guard let advertiserPHY = AdvertiserPhy(rawValue: data[11])
                else { return nil }
            
            let periodicAdvertisingInterval = PeriodicAdvertisingInterval(rawValue: UInt16(littleEndian: UInt16(bytes: (data[12], data[13]))))
            
            guard let advertiserClockAccuracy = LowEnergyClockAccuracy(rawValue: data[14])
                else { return nil }
            
            self.status = status
            self.syncHandle = syncHandle
            self.advertisingSID = advertisingSID
            self.advertiserAddressType = advertiserAddressType
            self.advertiserAddress = advertiserAddress
            self.advertiserPHY = advertiserPHY
            self.periodicAdvertisingInterval = periodicAdvertisingInterval
            self.advertiserClockAccuracy = advertiserClockAccuracy
        }
        
        public enum AdvertiserPhy: UInt8 { // Advertiser_PHY
            
            /// Advertiser PHY is LE 1M
            case le1m       = 0x01
            
            /// Advertiser PHY is LE 2M
            case le2m       = 0x02
            
            /// Advertiser PHY is LE Coded
            case coded      = 0x03
        }
        
        public struct PeriodicAdvertisingInterval: RawRepresentable, Equatable, Hashable, Comparable {
            
            /// 7.5 msec
            public static let min = PeriodicAdvertisingInterval(0x0006)
            
            /// 4000 msec
            public static let max = PeriodicAdvertisingInterval(0xFFFF)
            
            public let rawValue: UInt16
            
            public init(rawValue: UInt16) {
                
                self.rawValue = rawValue
            }
            
            /// Time = N * 1.25 msec
            public var miliseconds: Double {
                
                return Double(rawValue) * 1.25
            }
            
            // Private, unsafe
            private init(_ rawValue: UInt16) {
                self.rawValue = rawValue
            }
            
            // Equatable
            public static func == (lhs: PeriodicAdvertisingInterval, rhs: PeriodicAdvertisingInterval) -> Bool {
                
                return lhs.rawValue == rhs.rawValue
            }
            
            // Comparable
            public static func < (lhs: PeriodicAdvertisingInterval, rhs: PeriodicAdvertisingInterval) -> Bool {
                
                return lhs.rawValue < rhs.rawValue
            }
            
            // Hashable
            public var hashValue: Int {
                
                return Int(rawValue)
            }
        }
    }
    
    /// LE Periodic Advertising Report Event
    ///
    /// The event indicates that the Controller has received a Periodic Advertising packet.
    public struct PeriodicAdvertisingReportEventParameter: HCIEventParameter {
        
        public static let event = LowEnergyEvent.periodicAdvertisingReport // 0x0F
        
        /// Minimum length
        public static let length = 7
        
        public let syncHandle: UInt16 // Sync_Handle
        
        public let txPower: LowEnergyTxPower
        
        public let rssi: RSSI
        
        /// This parameter is intended to be used in a future feature.
        public let unused: UInt8 // This value must be used by the Controller.
        
        public let dataStatus: DataStatus
        
        public let data: Data
        
        public init?(data: Data) {
            
            guard data.count >= type(of: self).length
                else { return nil }
            
            let syncHandle = UInt16(littleEndian: UInt16(bytes: (data[0], data[1])))
            
            guard let txPower = LowEnergyTxPower(rawValue: Int8(bitPattern: data[2]))
                else { return nil }

            guard let rssi = RSSI(rawValue: Int8(bitPattern: data[3]))
                else { return nil }
            
            let unused = data[4]
            
            guard let dataStatus = DataStatus(rawValue: data[5])
                else { return nil }
            
            let dataLength = Int(data[6])
            
            if dataLength > 0 {
                
                let bytes = data[7 ... (7 + dataLength)]
                
                self.data = Data(bytes)
                
            } else {
                
                self.data = Data()
            }
            
            self.syncHandle = syncHandle
            self.txPower = txPower
            self.rssi = rssi
            self.unused = unused
            self.dataStatus = dataStatus
            
            assert(data.count == dataLength, "Invalid data length")
            assert(unused == 0xFF, "Invalid value for unused byte")
        }
        
        public enum DataStatus: UInt8 {
            
            /// Data complete
            case complete       = 0x00
            
            /// Data incomplete, more data to come
            case incomplete     = 0x01
            
            /// Data incomplete, data truncated, no more to come
            case truncated      = 0x02
        }
    }
    
    /// LE Periodic Advertising Sync Lost Event
    ///
    /// The event indicates that the Controller has not received a Periodic Advertising packet identified
    /// by Sync_Handle within the timeout period.
    public struct PeriodicAdvertisingSyncLostEventParameter: HCIEventParameter {
        
        public static let event = LowEnergyEvent.periodicAdvertisingSyncLost // 0x10
        
        public static let length = 2
        
        public let syncHandle: UInt16 // Sync_Handle
        
        public init?(data: Data) {
            
            guard data.count == type(of: self).length
                else { return nil }
            
            let syncHandle = UInt16(littleEndian: UInt16(bytes: (data[0], data[1])))
            
            self.syncHandle = syncHandle
        }
    }
    
    /// LE Advertising Set Terminated Event
    ///
    /// The event indicates that the Controller has terminated advertising in the advertising sets specified by the Advertising_Handle parameter.
    public struct AdvertisingSetTerminatedEventParameter: HCIEventParameter {
        
        public static let event = LowEnergyEvent.advertisingSetTerminated // 0x12
        
        public static let length: Int = 5
        
        public let status: HCIStatus
        
        public let advertisingHandle: UInt8
        
        public let connectionHandle: UInt16 // Connection_Handle
        
        public let numCompletedExtendedAdvertisingEvents: UInt8
        
        public init?(data: Data) {
            
            guard data.count == type(of: self).length
                else { return nil }
            
            guard let status = HCIStatus(rawValue: data[0])
                else { return nil }
            
            let advertisingHandle =  data[1]
            
            let connectionHandle = UInt16(littleEndian: UInt16(bytes: (data[2], data[3])))
            
            let numCompletedExtendedAdvertisingEvents = data[4]
            
            self.status = status
            self.advertisingHandle = advertisingHandle
            self.connectionHandle = connectionHandle
            self.numCompletedExtendedAdvertisingEvents = numCompletedExtendedAdvertisingEvents
        }
    }
    
    /// LE Scan Request Received Event
    ///
    /// The vent indicates that a SCAN_REQ PDU or an AUX_SCAN_REQ PDU has been received by the advertiser.
    /// The request contains a device address from a scanner that is allowed by the advertising filter policy.
    /// The advertising set is identified by Advertising_Handle.
    public struct ScanRequestReceivedEventParameter: HCIEventParameter {
        
        public static let event = LowEnergyEvent.scanRequestReceived // 0x13
        
        public static let length: Int = 8
        
        public let advertisingHandle: UInt8
        
        public let scannerAddressType: LowEnergyAddressType
        
        public let scannerAddress: Address
        
        public init?(data: Data) {
            
            guard data.count == type(of: self).length
                else { return nil }
            
            let advertisingHandle =  data[0]
            
            guard let scannerAddressType = LowEnergyAddressType(rawValue: data[1])
                else { return nil }
            
            let scannerAddress = Address(littleEndian: Address(bytes: (data[2], data[3], data[4], data[5], data[6], data[7])))
            
            self.advertisingHandle = advertisingHandle
            self.scannerAddressType = scannerAddressType
            self.scannerAddress = scannerAddress
        }
    }
    
    /// LE Channel Selection Algorithm Event
    ///
    /// The LE Channel Selection Algorithm Event indicates which channel selection algorithm is used on a data channel connection.
    public struct ChannelSelectionAlgorithmEventParameter: HCIEventParameter {
        
        public static let event = LowEnergyEvent.channelSelectionAlgorithm // 0x14
        
        public static let length: Int = 3
    
        public let connectionHandle: UInt16 // Connection_Handle
        
        public let channelSelectionAlgorithm: ChannelSelectionAlgorithm
        
        public init?(data: Data) {
            guard data.count == type(of: self).length
                else { return nil }
            
            let connectionHandle = UInt16(littleEndian: UInt16(bytes: (data[0], data[1])))
            
            guard let channelSelectionAlgorithm = ChannelSelectionAlgorithm.init(rawValue: data[2])
                else { return nil }
            
            self.connectionHandle = connectionHandle
            self.channelSelectionAlgorithm = channelSelectionAlgorithm
        }
        
        public enum ChannelSelectionAlgorithm: UInt8 { // Channel_Selection_Algorithm
            
            /// LE Channel Selection Algorithm #1 is used
            case algorithm1         = 0x00
            
            /// LE Channel Selection Algorithm #2 is used
            case algorithm2         = 0x01
        }
    }
}
