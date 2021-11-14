//
//  GATTClient.swift
//  Bluetooth
//
//  Created by Alsey Coleman Miller on 2/29/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import Foundation
import Bluetooth

/// GATT Client
public actor GATTClient {
    
    // MARK: - Properties
    
    public var log: ((String) -> ())?
    
    public var maximumTransmissionUnit: ATTMaximumTransmissionUnit {
        get async {
            return await self.connection.maximumTransmissionUnit
        }
    }
    
    public let preferredMaximumTransmissionUnit: ATTMaximumTransmissionUnit
    
    internal private(set) var didExchangeMTU = false
    
    internal let connection: ATTConnection
    
    /// Whether the client is currently writing a long value.
    internal private(set) var inLongWrite: Bool = false
    
    /// Notications
    internal private(set) var notifications = [UInt16: Notification]()
    
    /// Indications
    internal private(set) var indications = [UInt16: Notification]()
    
    // MARK: - Initialization
    
    public init(
        socket: L2CAPSocket,
        maximumTransmissionUnit: ATTMaximumTransmissionUnit = .default,
        log: ((String) -> ())? = nil
    ) {
        self.connection = ATTConnection(socket: socket)
        self.preferredMaximumTransmissionUnit = maximumTransmissionUnit
        self.log = log
        
        // async setup tasks
        Task { [weak self] in
            // setup notifications and indications
            await self?.registerATTHandlers()
            // queue MTU exchange if not default value
            if maximumTransmissionUnit > .default {
                await self?.exchangeMTU()
            }
        }
    }
    
    // MARK: - Methods
    
    // MARK: Requests
    
    /// Discover All Primary Services
    ///
    /// This sub-procedure is used by a client to discover all the primary services on a server.
    /// ![Image](https://github.com/PureSwift/Bluetooth/raw/master/Assets/DiscoverAllPrimaryServices.png)
    ///
    /// - Parameter completion: The completion closure.
    public func discoverAllPrimaryServices() async throws -> [Service] {
        
        /// The Attribute Protocol Read By Group Type Request shall be used with 
        /// the Attribute Type parameter set to the UUID for «Primary Service». 
        /// The Starting Handle shall be set to 0x0001 and the Ending Handle shall be set to 0xFFFF.
        try await discoverServices(
            start: 0x0001,
            end: 0xFFFF,
            primary: true
        )
    }
    
    /// Discover Primary Service by Service UUID
    /// 
    /// This sub-procedure is used by a client to discover a specific primary service on a server
    /// when only the Service UUID is known. The specific primary service may exist multiple times on a server. 
    /// The primary service being discovered is identified by the service UUID.
    /// ![Image](https://github.com/PureSwift/Bluetooth/raw/master/Assets/DiscoverPrimaryServiceByServiceUUID.png)
    ///
    /// - Parameter uuid: The UUID of the service to find.
    /// - Parameter completion: The completion closure.
    public func discoverPrimaryServices(
        by uuid: BluetoothUUID
    ) async throws -> [Service]{
        
        // The Attribute Protocol Find By Type Value Request shall be used with the Attribute Type
        // parameter set to the UUID for «Primary Service» and the Attribute Value set to the 16-bit
        // Bluetooth UUID or 128-bit UUID for the specific primary service. 
        // The Starting Handle shall be set to 0x0001 and the Ending Handle shall be set to 0xFFFF.
        return try await discoverServices(
            uuid: uuid,
            start: 0x0001,
            end: 0xFFFF,
            primary: true
        )
    }
    
    /// Discover All Characteristics of a Service
    /// 
    /// This sub-procedure is used by a client to find all the characteristic declarations within 
    /// a service definition on a server when only the service handle range is known.
    /// The service specified is identified by the service handle range.
    /// ![Image](https://github.com/PureSwift/Bluetooth/raw/master/Assets/DiscoverAllCharacteristics.png)
    ///
    /// - Parameter service: The service.
    /// - Parameter completion: The completion closure.
    public func discoverAllCharacteristics(of service: Service) async throws -> [Characteristic] {
        
        // The Attribute Protocol Read By Type Request shall be used with the Attribute Type
        // parameter set to the UUID for «Characteristic» The Starting Handle shall be set to 
        // starting handle of the specified service and the Ending Handle shall be set to the 
        // ending handle of the specified service.
        
        return try await discoverCharacteristics(service: service)
    }
    
    /// Discover Characteristics by UUID
    /// 
    /// This sub-procedure is used by a client to discover service characteristics on a server when 
    /// only the service handle ranges are known and the characteristic UUID is known. 
    /// The specific service may exist multiple times on a server. 
    /// The characteristic being discovered is identified by the characteristic UUID.
    /// ![Image](https://github.com/PureSwift/Bluetooth/raw/master/Assets/DiscoverCharacteristicsByUUID.png)
    ///
    /// - Parameter service: The service of the characteristics to find.
    /// - Parameter uuid: The UUID of the characteristics to find.
    /// - Parameter completion: The completion closure.
    public func discoverCharacteristics(
        of service: Service,
        by uuid: BluetoothUUID
    ) async throws -> [Characteristic] {
        
        // The Attribute Protocol Read By Type Request is used to perform the beginning of the sub-procedure.
        // The Attribute Type is set to the UUID for «Characteristic» and the Starting Handle and Ending Handle
        // parameters shall be set to the service handle range.
        return try await discoverCharacteristics(uuid: uuid, service: service)
    }
    
    /// Read Characteristic Value
    ///
    /// This sub-procedure is used to read a Characteristic Value from a server when the client knows
    /// the Characteristic Value Handle.
    ///
    /// ![Image](https://github.com/PureSwift/Bluetooth/raw/master/Assets/ReadCharacteristicValue.png)
    public func readCharacteristic(_ characteristic: Characteristic) async throws -> Data {
        // read value and try to read blob if too big
        return try await readAttributeValue(characteristic.handle.value)
    }
    
    /// Read Using Characteristic UUID
    ///
    /// This sub-procedure is used to read a Characteristic Value from a server when the client
    /// only knows the characteristic UUID and does not know the handle of the characteristic.
    ///
    /// ![Image](https://github.com/PureSwift/Bluetooth/raw/master/Assets/ReadUsingCharacteristicUUID.png)
    public func readCharacteristics(
        using uuid: BluetoothUUID,
        handleRange: (start: UInt16, end: UInt16) = (.min, .max)
    ) async throws -> [UInt16: Data] {
        precondition(handleRange.start < handleRange.end)
        return try await withCheckedThrowingContinuation() { continuation in
            Task {
                // The Attribute Protocol Read By Type Request is used to perform the sub-procedure.
                // The Attribute Type is set to the known characteristic UUID and the Starting Handle and Ending Handle parameters
                // shall be set to the range over which this read is to be performed. This is typically the handle range for the service in which the characteristic belongs.
                let request = ATTReadByTypeRequest(
                    startHandle: handleRange.start,
                    endHandle: handleRange.end,
                    attributeType: uuid
                )
                let operation = ReadUsingUUIDOperation(uuid: uuid) { result in
                    continuation.resume(with: result)
                }
                let response = try await send(request, response: ATTReadByTypeResponse.self)
                readByTypeResponse(response, operation: operation)
            }
        }
    }
    
    /// Read Multiple Characteristic Values
    ///
    /// This sub-procedure is used to read multiple Characteristic Values from a server when the client
    /// knows the Characteristic Value Handles.
    ///
    /// ![Image](https://github.com/PureSwift/Bluetooth/raw/master/Assets/ReadMultipleCharacteristicValues.png)
    ///
    /// - Note: A client should not use this request for attributes when the Set Of Values parameter could be `(ATT_MTU–1)`
    /// as it will not be possible to determine if the last attribute value is complete, or if it overflowed.
    public func readCharacteristics(_ characteristics: [Characteristic], completion: @escaping (GATTClientResponse<Data>) -> ()) {
        
        // The Attribute Protocol Read Multiple Request is used with the Set Of Handles parameter set to the Characteristic Value Handles.
        // The Read Multiple Response returns the Characteristic Values in the Set Of Values parameter.
        
        let handles = characteristics.map { $0.handle.value }
        
        guard let pdu = ATTReadMultipleRequest(handles: handles)
            else { fatalError("Must provide at least 2 characteristics") }
        
        let operation = ReadMultipleOperation(characteristics: characteristics, completion: completion)
        
        send(pdu) { [unowned self] in
            self.readMultipleResponse($0, operation: operation)
        }
    }
    
    /**
     Write Characteristic
     
     Uses the appropriate procecedure to write the characteristic value.
     */
    public func writeCharacteristic(_ characteristic: Characteristic,
                                    data: Data,
                                    reliableWrites: Bool = true,
                                    completion: ((GATTClientResponse<()>) -> ())?) {
        
        writeAttribute(characteristic.handle.value,
                       data: data,
                       reliableWrites: reliableWrites,
                       completion: completion)
    }
    
    /**
     Discover All Characteristic Descriptors
     
     This sub-procedure is used by a client to find all the characteristic descriptor’s Attribute Handles and Attribute Types within a characteristic definition when only the characteristic handle range is known. The characteristic specified is identified by the characteristic handle range.
     
     ![Image](https://github.com/PureSwift/Bluetooth/raw/master/Assets/DiscoverAllCharacteristicDescriptors.png)
     */
    public func discoverDescriptors(for characteristic: Characteristic,
                                    service: (declaration: Service, characteristics: [Characteristic]),
                                    completion: @escaping (GATTClientResponse<[Descriptor]>) -> ()) {
        
        /**
         The Attribute Protocol Find Information Request shall be used with the Starting Handle set
         to the handle of the specified characteristic value + 1 and the Ending Handle set to the
         ending handle of the specified characteristic.
         */
        
        let start = characteristic.handle.value + 1
        
        let end = endHandle(for: characteristic, service: service)
        
        let operation = DescriptorDiscoveryOperation(start: start, end: end, completion: completion)
        
        discoverDescriptors(operation: operation)
    }
    
    /// Read Characteristic Descriptor
    ///
    /// This sub-procedure is used to read a characteristic descriptor from a server when the client knows
    /// the characteristic descriptor declaration’s Attribute handle.
    ///
    /// ![Image](https://github.com/PureSwift/Bluetooth/raw/master/Assets/ReadCharacteristicValue.png)
    public func readDescriptor(_ descriptor: Descriptor,
                               completion: @escaping (GATTClientResponse<Data>) -> ()) {
        
        /**
         The Attribute Protocol Read Request is used for this sub-procedure. The Read Request is used with the Attribute Handle parameter set to the characteristic descriptor handle. The Read Response returns the characteristic descriptor value in the Attribute Value parameter.
         
         An Error Response shall be sent by the server in response to the Read Request if insufficient authentication, insufficient authorization, insufficient encryption key size is used by the client, or if a read operation is not permitted on the Characteristic Value. The Error Code parameter is set accordingly.
         */
        
        // read value and try to read blob if too big
        readAttributeValue(descriptor.handle, completion: completion)
    }
    
    /**
     Write Descriptor
     
     Uses the appropriate procecedure to write the characteristic descriptor value.
     */
    public func writeDescriptor(_ descriptor: Descriptor,
                                data: Data,
                                reliableWrites: Bool = true,
                                completion: ((GATTClientResponse<()>) -> ())?) {
        
        writeAttribute(descriptor.handle,
                       data: data,
                       reliableWrites: reliableWrites,
                       completion: completion)
    }
    
    /**
     Notifications
     
     This sub-procedure is used when a server is configured to notify a Characteristic Value to a client without expecting any Attribute Protocol layer acknowledgment that the notification was successfully received.
     
     ![Image](https://github.com/PureSwift/Bluetooth/raw/master/Assets/Notifications.png)
     */
    public func clientCharacteristicConfiguration(
        notification: Notification?,
        indication: Notification?,
        for characteristic: Characteristic,
        descriptors: [GATTClient.Descriptor]
    ) async throws {
        
        guard let descriptor = descriptors.first(where: { $0.uuid == .clientCharacteristicConfiguration })
            else { completion(.failure(GATTClientError.clientCharacteristicConfigurationNotAllowed(characteristic))); return }
        
        var clientConfiguration = GATTClientCharacteristicConfiguration()
        
        if notification != nil {
            clientConfiguration.configuration.insert(.notify)
        }
        
        if indication != nil {
            clientConfiguration.configuration.insert(.indicate)
        }
        
        writeDescriptor(descriptor, data: clientConfiguration.data) { [unowned self] (response) in
            
            switch response {
                
            case .failure:
                break
                
            case .success:
                
                self.notifications[characteristic.handle.value] = notification
                self.indications[characteristic.handle.value] = indication
            }
            
            completion(response)
        }
    }
    
    // MARK: - Private Methods
    
    private func registerATTHandlers() async  {
        
        // value notifications / indications
        await connection.register { [weak self] in await self?.notification($0) }
        await connection.register { [weak self] in await self?.indication($0) }
    }
    
    private func send <Request: ATTProtocolDataUnit, Response: ATTProtocolDataUnit> (
        _ request: Request,
        response: Response.Type
    ) async throws -> ATTResponse<Response> {
        
        let log = self.log
        log?("Request: \(request)")
        
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else { return }
            Task {
                let responseType: ATTProtocolDataUnit.Type = Response.self
                // callback if no I/O errors or disconnect
                let callback: (ATTProtocolDataUnit) -> () = {
                    log?("Response: \($0)")
                    continuation.resume(returning: ATTResponse<Response>($0))
                }
                guard let _ = await self.connection.send(request, response: (callback, responseType))
                    else { fatalError("Could not add PDU to queue: \(request)") }
                // do I/O
                do {
                    // write pending
                    let didWrite = try await self.connection.write()
                    assert(didWrite, "Expected queued write operation")
                    try await self.connection.read()
                }
                catch {
                    // I/O error
                    assert(type(of: error) != ATTErrorResponse.self)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    @inline(__always)
    private func send<Request: ATTProtocolDataUnit>(_ request: Request) async throws {
        
        log?("Request: \(request)")
        
        guard let _ = await connection.send(request)
            else { fatalError("Could not add PDU to queue: \(request)") }
        
        // write pending PDU
        let didWrite = try await self.connection.write()
        assert(didWrite, "Expected queued write operation")
    }
    
    internal func endHandle(
        for characteristic: Characteristic,
        service: (declaration: Service, characteristics: [Characteristic])
    ) -> UInt16 {
        
        // calculate ending handle of characteristic
        let end: UInt16
        
        guard let index = service.characteristics.firstIndex(where: { $0.handle.declaration == characteristic.handle.declaration })
            else { fatalError("Invalid characteristics \(service.characteristics.map { $0.uuid })") }
        
        let nextIndex = index + 1
        
        // get start handle of next characteristic
        if nextIndex < service.characteristics.count {
            let nextCharacteristic = service.characteristics[nextIndex]
            end = nextCharacteristic.handle.declaration - 1
        } else {
            // use service end handle
            end = service.declaration.end
        }
        // FIXME: Handle descriptors
        
        return end
    }
    
    // MARK: Requests
    
    /// Exchange MTU (should only be called once if not using default MTU)
    internal func exchangeMTU() async {
        assert(didExchangeMTU == false)
        let clientMTU = preferredMaximumTransmissionUnit
        let request = ATTMaximumTransmissionUnitRequest(clientMTU: clientMTU.rawValue)
        do {
            let response = try await send(request, response: ATTMaximumTransmissionUnitResponse.self)
            await exchangeMTUResponse(response)
        } catch {
            // I/O error
            assert(error as? ATTErrorResponse == nil)
            log?("Could not exchange MTU: \(error)")
        }
    }
    
    internal func discoverServices(
        uuid: BluetoothUUID? = nil,
        start: UInt16 = 0x0001,
        end: UInt16 = 0xffff,
        primary: Bool = true
    ) async throws -> [Service] {
        return try await withCheckedThrowingContinuation() { continuation in
            Task { [weak self] in
                guard let self = self else { return }
                let serviceType = GATTUUID(primaryService: primary)
                let operation = DiscoveryOperation<Service>(
                    uuid: uuid,
                    start: start,
                    end: end,
                    type: serviceType
                ) { result in
                    continuation.resume(with: result)
                }
                
                do {
                    if let uuid = uuid {
                        let request = ATTFindByTypeRequest(
                            startHandle: start,
                            endHandle: end,
                            attributeType: serviceType.rawValue,
                            attributeValue: uuid.littleEndian.data
                        )
                        // perform I/O
                        let response = try await self.send(request, response: ATTFindByTypeResponse.self)
                        try await self.findByTypeResponse(response, operation: operation)
                    } else {
                        let request = ATTReadByGroupTypeRequest(
                            startHandle: start,
                            endHandle: end,
                            type: serviceType.uuid
                        )
                        let response = try await self.send(request, response: ATTReadByGroupTypeResponse.self)
                        try await self.readByGroupTypeResponse(response, operation: operation)
                    }
                } catch {
                    assert(error as? ATTErrorResponse == nil)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func discoverCharacteristics(
        uuid: BluetoothUUID? = nil,
        service: Service
    ) async throws -> [Characteristic] {
        return try await withCheckedThrowingContinuation() { continuation in
            Task {
                do {
                    let attributeType = GATTUUID.characteristic
                    let operation = DiscoveryOperation<Characteristic>(
                        uuid: uuid,
                        start: service.handle,
                        end: service.end,
                        type: attributeType
                    ) { result in
                        continuation.resume(with: result)
                    }
                    let request = ATTReadByTypeRequest(
                        startHandle: service.handle,
                        endHandle: service.end,
                        attributeType: attributeType.uuid
                    )
                    let response = try await send(request, response: ATTReadByTypeResponse.self)
                    try await readByTypeResponse(response, operation: operation)
                }
                catch {
                    assert(error as? ATTErrorResponse == nil)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func discoverDescriptors(operation: DescriptorDiscoveryOperation) async throws {
        assert(operation.start <= operation.end, "Invalid range")
        let request = ATTFindInformationRequest(startHandle: operation.start, endHandle: operation.end)
        let response = try await send(request, response: ATTFindInformationResponse.self)
        try await findInformationResponse(response, operation: operation)
    }
    
    /// Read Characteristic Value
    ///
    /// This sub-procedure is used to read a Characteristic Value from a server when the client knows
    /// the Characteristic Value Handle.
    ///
    /// ![Image](https://github.com/PureSwift/Bluetooth/raw/master/Assets/ReadCharacteristicValue.png)
    private func readAttributeValue(_ handle: UInt16) async throws -> Data {
        // The Attribute Protocol Read Request is used with the
        // Attribute Handle parameter set to the Characteristic Value Handle.
        // The Read Response returns the Characteristic Value in the Attribute Value parameter.
        return try await withCheckedThrowingContinuation() { continuation in
            Task {
                // read value and try to read blob if too big
                let operation = ReadOperation(handle: handle) { result in
                    continuation.resume(with: result)
                }
                let request = ATTReadRequest(handle: handle)
                let response = try await send(request, response: ATTReadResponse.self)
                try await readResponse(response, operation: operation)
            }
        }
    }
    
    /// Read Long Characteristic Value
    ///
    /// This sub-procedure is used to read a Characteristic Value from a server when the client knows
    /// the Characteristic Value Handle and the length of the Characteristic Value is longer than can
    /// be sent in a single Read Response Attribute Protocol message.
    ///
    /// ![Image](https://github.com/PureSwift/Bluetooth/raw/master/Assets/ReadLongCharacteristicValues.png)
    @inline(__always)
    private func readLongAttributeValue(_ operation: ReadOperation) async throws {
        
        // The Attribute Protocol Read Blob Request is used to perform this sub-procedure.
        // The Attribute Handle shall be set to the Characteristic Value Handle of the Characteristic Value to be read.
        // The Value Offset parameter shall be the offset within the Characteristic Value to be read. To read the
        // complete Characteristic Value the offset should be set to 0x00 for the first Read Blob Request.
        // The offset for subsequent Read Blob Requests is the next octet that has yet to be read.
        // The Read Blob Request is repeated until the Read Blob Response’s Part Attribute Value parameter is shorter than (ATT_MTU-1).
        
        let request = ATTReadBlobRequest(
            handle: operation.handle,
            offset: operation.offset
        )
        
        let response = try await send(request, response: ATTReadBlobResponse.self)
        try await readBlobResponse(response, operation: operation)
    }
    
    private func writeAttribute(
        _ handle: UInt16,
        data: Data,
        reliableWrites: Bool,
        completion: ((GATTClientResponse<()>) -> ())?
    ) async throws {
        
        // short value
        let shortValueLength = await Int(maximumTransmissionUnit.rawValue) - 3 // ATT_MTU - 3
        if data.count <= shortValueLength {
            if let completion = completion {
                try await writeAttributeValue(
                    handle,
                    data: data,
                    completion: completion
                )
            } else {
                try await writeAttributeCommand(handle, data: data)
            }
        } else {
            let completion = completion ?? { _ in }
            try await writeLongAttributeValue(
                handle,
                data: data,
                reliableWrites: reliableWrites,
                completion: completion
            )
        }
    }
    
    private func writeAttributeCommand(_ attribute: UInt16, data: Data) async throws {
        let length = await Int(maximumTransmissionUnit.rawValue) - 3
        let data = Data(data.prefix(length))
        let command = ATTWriteCommand(handle: attribute, value: data)
        try await send(command)
    }
    
    /// Write attribute request.
    private func writeAttributeValue(
        _ attribute: UInt16,
        data: Data,
        completion: @escaping (GATTClientResponse<()>) -> ()
    ) async throws {
        let length = await Int(maximumTransmissionUnit.rawValue) - 3
        let data = Data(data.prefix(length))
        let request = ATTWriteRequest(handle: attribute, value: data)
        let response = try await send(request, response: ATTWriteResponse.self)
        writeResponse(response, completion: completion)
    }
    
    private func writeLongAttributeValue(
        _ attribute: UInt16,
        data: Data,
        reliableWrites: Bool = false,
        completion: @escaping (GATTClientResponse<()>) -> ()
    ) async throws {
        
        // The Attribute Protocol Prepare Write Request and Execute Write Request are used to perform this sub-procedure.
        // The Attribute Handle parameter shall be set to the Characteristic Value Handle of the Characteristic Value to be written.
        // The Part Attribute Value parameter shall be set to the part of the Attribute Value that is being written.
        // The Value Offset parameter shall be the offset within the Characteristic Value to be written.
        // To write the complete Characteristic Value the offset should be set to 0x0000 for the first Prepare Write Request.
        // The offset for subsequent Prepare Write Requests is the next octet that has yet to be written.
        // The Prepare Write Request is repeated until the complete Characteristic Value has been transferred,
        // after which an Executive Write Request is used to write the complete value.
        
        guard inLongWrite == false
            else { completion(.failure(GATTClientError.inLongWrite)); return }
        
        let partLength = await Int(maximumTransmissionUnit.rawValue) - 5
        let firstValuePart = Data(data.prefix(partLength))
        
        let request = ATTPrepareWriteRequest(
            handle: attribute,
            offset: 0x00,
            partValue: firstValuePart
        )
        
        let operation = WriteOperation(
            handle: attribute,
            data: data,
            reliableWrites: reliableWrites,
            lastRequest: request,
            completion: completion
        )
        
        let response = try await send(request, response: ATTPrepareWriteResponse.self)
        try await prepareWriteResponse(response, operation: operation)
    }
    
    /**
     Signed Write Without Response
     
     This sub-procedure is used to write a Characteristic Value to a server when the client knows the Characteristic Value Handle and the ATT Bearer is not encrypted. This sub-procedure shall only be used if the Characteristic Properties authenticated bit is enabled and the client and server device share a bond.
     
     If the authenticated Characteristic Value that is written is the wrong size, has an invalid value as defined by the profile, or the signed value does not authenticate the client, then the write shall not succeed and no error shall be gener- ated by the server.
     
     ![Image](https://github.com/PureSwift/Bluetooth/raw/master/Assets/SignedWriteWithoutResponse.png)
     
     - Note: On BR/EDR, the ATT Bearer is always encrypted, due to the use of Security Mode 4, therefore this sub-procedure shall not be used.
     */
    private func writeSignedCharacteristicCommand(
        _ characteristic: Characteristic,
        data: Data
    ) async throws {
        
        // This sub-procedure only writes the first (ATT_MTU – 15) octets of an Attribute Value.
        // This sub-procedure cannot be used to write a long Attribute.
        
        // The Attribute Protocol Write Command is used for this sub-procedure.
        // The Attribute Handle parameter shall be set to the Characteristic Value Handle.
        // The Attribute Value parameter shall be set to the new Characteristic Value authenticated by signing the value.
        
        // If a connection is already encrypted with LE security mode 1, level 2 or level 3 as defined in [Vol 3] Part C,
        // Section 10.2 then, a Write Without Response as defined in Section 4.9.1 shall be used instead of
        // a Signed Write Without Response.
        
        let dataLength = await Int(maximumTransmissionUnit.rawValue) - 15
        let data = Data(data.prefix(dataLength))
        
        // TODO: Sign Data
        
        let pdu = ATTWriteCommand(handle: characteristic.handle.value, value: data)
        try await send(pdu)
    }
    
    // MARK: - Callbacks
    
    private func exchangeMTUResponse(_ response: ATTResponse<ATTMaximumTransmissionUnitResponse>) async {
        assert(didExchangeMTU == false)
        switch response {
        case let .failure(errorResponse):
            log?("Could not exchange MTU: \(errorResponse)")
        case let .success(pdu):
            let clientMTU = preferredMaximumTransmissionUnit
            let finalMTU = ATTMaximumTransmissionUnit(server: pdu.serverMTU, client: clientMTU.rawValue)
            log?("MTU Exchange (\(clientMTU) -> \(finalMTU))")
            await self.connection.setMaximumTransmissionUnit(finalMTU)
            self.didExchangeMTU = true
        }
    }
    
    private func readByGroupTypeResponse(
        _ response: ATTResponse<ATTReadByGroupTypeResponse>,
        operation: DiscoveryOperation<Service>
    ) async throws {
        
        // Read By Group Type Response returns a list of Attribute Handle, End Group Handle, and Attribute Value tuples
        // corresponding to the services supported by the server. Each Attribute Value contained in the response is the 
        // Service UUID of a service supported by the server. The Attribute Handle is the handle for the service declaration.
        // The End Group Handle is the handle of the last attribute within the service definition. 
        // The Read By Group Type Request shall be called again with the Starting Handle set to one greater than the 
        // last End Group Handle in the Read By Group Type Response.
        
        switch response {
        case let .failure(errorResponse):
            operation.failure(errorResponse)
        case let .success(response):
            // store PDU values
            for serviceData in response.attributeData {
                
                guard let littleEndianServiceUUID = BluetoothUUID(data: serviceData.value) else {
                    operation.completion(.failure(Error.invalidResponse(response)))
                    return
                }
                
                let serviceUUID = BluetoothUUID(littleEndian: littleEndianServiceUUID)
                let service = Service(
                    uuid: serviceUUID,
                    isPrimary: operation.type == .primaryService,
                    handle: serviceData.attributeHandle,
                    end: serviceData.endGroupHandle
                )
                
                operation.foundData.append(service)
            }
            
            // get more if possible
            let lastEnd = response.attributeData.last?.endGroupHandle ?? 0x00
            
            // prevent infinite loop
            guard lastEnd >= operation.start else {
                operation.completion(.failure(Error.invalidResponse(response)))
                return
            }
            
            guard lastEnd < .max // End of database
                else { operation.success(); return }
            
            operation.start = lastEnd + 1
            
            if lastEnd < operation.end {
                let request = ATTReadByGroupTypeRequest(
                    startHandle: operation.start,
                    endHandle: operation.end,
                    type: operation.type.uuid
                )
                let response = try await send(request, response: ATTReadByGroupTypeResponse.self)
                try await readByGroupTypeResponse(response, operation: operation)
            } else {
                operation.success()
            }
        }
    }
    
    private func findByTypeResponse(
        _ response: ATTResponse<ATTFindByTypeResponse>,
        operation: DiscoveryOperation<Service>
    ) async throws {
        
        // Find By Type Value Response returns a list of Attribute Handle ranges. 
        // The Attribute Handle range is the starting handle and the ending handle of the service definition.
        // If the Attribute Handle range for the Service UUID being searched is returned and the End Found Handle 
        // is not 0xFFFF, the Find By Type Value Request may be called again with the Starting Handle set to one 
        // greater than the last Attribute Handle range in the Find By Type Value Response.
        
        switch response {
        case let .failure(errorResponse):
            operation.failure(errorResponse)
        case let .success(response):
            guard let serviceUUID = operation.uuid
                else { fatalError("Should have UUID specified") }
            
            // pre-allocate array
            operation.foundData.reserveCapacity(operation.foundData.count + response.handles.count)
            
            // store PDU values
            for serviceData in response.handles {
                let service = Service(
                    uuid: serviceUUID,
                    isPrimary: operation.type == .primaryService,
                    handle: serviceData.foundAttribute,
                    end: serviceData.groupEnd
                )
                operation.foundData.append(service)
            }
            
            // get more if possible
            let lastEnd = response.handles.last?.groupEnd ?? 0x00
            
            guard lastEnd < .max // End of database
                else { operation.success(); return }
            
            operation.start = lastEnd + 1
            
            // need to continue scanning
            if lastEnd < operation.end {
                
                let request = ATTFindByTypeRequest(
                    startHandle: operation.start,
                    endHandle: operation.end,
                    attributeType: operation.type.rawValue,
                    attributeValue: serviceUUID.littleEndian.data
                )
                let response = try await send(request, response: ATTFindByTypeResponse.self)
                try await findByTypeResponse(response, operation: operation)
            } else {
                operation.success()
            }
        }
    }
    
    private func findInformationResponse(
        _ response: ATTResponse<ATTFindInformationResponse>,
        operation: DescriptorDiscoveryOperation
    ) async throws {
        
        /**
         Two possible responses can be sent from the server for the Find Information Request: Find Information Response and Error Response.
         
         Error Response is returned if an error occurred on the server.
         
         Find Information Response returns a list of Attribute Handle and Attribute Value pairs corresponding to the characteristic descriptors in the characteristic definition. The Attribute Handle is the handle for the characteristic descriptor declaration. The Attribute Value is the Characteristic Descriptor UUID.
         
         The Find Information Request shall be called again with the Starting Handle set to one greater than the last Attribute Handle in the Find Information Response.
         
         The sub-procedure is complete when the Error Response is received and the Error Code is set to Attribute Not Found or the Find Information Response has an Attribute Handle that is equal to the Ending Handle of the request.
         
         It is permitted to end the sub-procedure early if a desired Characteristic Descriptor is found prior to discovering all the characteristic descriptors of the specified characteristic.
         */
        
        switch response {
        case let .failure(errorResponse):
            operation.failure(errorResponse)
        case let .success(pdu):
            
            // pre-allocate array
            operation.foundDescriptors.reserveCapacity(operation.foundDescriptors.count + pdu.data.count)
            
            let foundData: [Descriptor]
            
            switch pdu.attributeData {
                
            case let .bit16(values):
                
                foundData = values.map { Descriptor(uuid: .bit16($0.uuid), handle: $0.handle) }
                
            case let .bit128(values):
                
                foundData = values.map { Descriptor(uuid: .bit128($0.uuid), handle: $0.handle) }
            }
            
            operation.foundDescriptors += foundData
            
            // get more if possible
            let lastHandle = foundData.last?.handle ?? 0x00
            
            // prevent infinite loop
            guard lastHandle >= operation.start
                else { operation.completion(.failure(Error.invalidResponse(pdu))); return }
            
            guard lastHandle < .max // End of database
                else { operation.success(); return }
            
            let start = lastHandle + 1
            
            // need to continue discovery
            if lastHandle != 0, start < operation.end {
                operation.start = start
                try await discoverDescriptors(operation: operation)
            } else {
                // end of service
                operation.success()
            }
        }
    }
    
    private func readByTypeResponse(
        _ response: ATTResponse<ATTReadByTypeResponse>,
        operation: DiscoveryOperation<Characteristic>
    ) async throws {
        typealias DeclarationAttribute = GATTDatabase.CharacteristicDeclarationAttribute
        typealias Attribute = GATTDatabase.Attribute
        
        // Read By Type Response returns a list of Attribute Handle and Attribute Value pairs corresponding to the
        // characteristics in the service definition. The Attribute Handle is the handle for the characteristic declaration. 
        // The Attribute Value is the Characteristic Properties, Characteristic Value Handle and Characteristic UUID. 
        // The Read By Type Request shall be called again with the Starting Handle set to one greater than the last 
        // Attribute Handle in the Read By Type Response.
        
        switch response {
        case let .failure(errorResponse):
            operation.failure(errorResponse)
        case let .success(pdu):
            
            // pre-allocate array
            operation.foundData.reserveCapacity(operation.foundData.count + pdu.data.count)
            
            // parse pdu data
            for characteristicData in pdu.attributeData {
                
                let handle = characteristicData.handle
                
                let attribute = Attribute(handle: handle,
                                          uuid: .characteristic,
                                          value: Data(characteristicData.value),
                                          permissions: [.read])
                
                guard let declaration = DeclarationAttribute(attribute: attribute)
                    else { operation.completion(.failure(Error.invalidResponse(pdu))); return }
                
                let characteristic = Characteristic(uuid: declaration.uuid,
                                                    properties: declaration.properties,
                                                    handle: (handle, declaration.valueHandle))
                
                operation.foundData.append(characteristic)
                
                // if we specified a UUID to be searched,
                // then call completion if it matches
                if let operationUUID = operation.uuid {
                    
                    guard characteristic.uuid != operationUUID
                        else { operation.success(); return }
                }
            }
            
            // get more if possible
            let lastEnd = pdu.attributeData.last?.handle ?? 0x00
            
            // prevent infinite loop
            guard lastEnd >= operation.start
                else { operation.completion(.failure(Error.invalidResponse(pdu))); return }
            
            operation.start = lastEnd + 1
            
            // need to continue discovery
            if lastEnd != 0, operation.start < operation.end {
                let request = ATTReadByTypeRequest(
                    startHandle: operation.start,
                    endHandle: operation.end,
                    attributeType: operation.type.uuid
                )
                let response = try await send(request, response: ATTReadByTypeResponse.self)
                try await readByTypeResponse(response, operation: operation)
            } else {
                // end of service
                operation.success()
            }
        }
    }
    
    /// Read Characteristic (or Descriptor) Value Response
    private func readResponse(
        _ response: ATTResponse<ATTReadResponse>,
        operation: ReadOperation
    ) async throws {
        
        // The Read Response only contains a Characteristic Value that is less than or equal to (ATT_MTU – 1) octets in length.
        // If the Characteristic Value is greater than (ATT_MTU – 1) octets in length, the Read Long Characteristic Value procedure
        // may be used if the rest of the Characteristic Value is required.
        
        switch response {
        case let .failure(error):
            operation.failure(error)
        case let .success(pdu):
            operation.data = pdu.attributeValue
            // short value
            let expectedLength = await Int(maximumTransmissionUnit.rawValue) - 1
            if pdu.attributeValue.count < expectedLength {
                operation.success()
            } else {
                // read blob
                try await readLongAttributeValue(operation)
            }
        }
    }
    
    /// Read Blob Response
    private func readBlobResponse(
        _ response: ATTResponse<ATTReadBlobResponse>,
        operation: ReadOperation
    ) async throws {
        
        // For each Read Blob Request a Read Blob Response is received with a portion of the Characteristic Value contained in the Part Attribute Value parameter.
        switch response {
        case let .failure(error):
            operation.failure(error)
        case let .success(pdu):
            operation.data += pdu.partAttributeValue
            // short value
            let expectedLength = await Int(maximumTransmissionUnit.rawValue) - 1
            if pdu.partAttributeValue.count < expectedLength {
                operation.success()
            } else {
                // read blob
                try await readLongAttributeValue(operation)
            }
        }
    }
    
    private func readMultipleResponse(_ response: ATTResponse<ATTReadMultipleResponse>, operation: ReadMultipleOperation) {
        switch response {
        case let .failure(error):
            operation.failure(error)
        case let .success(pdu):
            operation.success(pdu.values)
        }
    }
    
    private func readByTypeResponse(_ response: ATTResponse<ATTReadByTypeResponse>, operation: ReadUsingUUIDOperation) {
        
        // Read By Type Response returns a list of Attribute Handle and Attribute Value pairs corresponding to the characteristics
        // contained in the handle range provided.
        
        switch response {
        case let .failure(error):
            operation.failure(error)
        case let .success(pdu):
            operation.success(pdu.attributeData)
        }
    }
    
    /**
     Write Response
     
     A Write Response shall be sent by the server if the write of the Characteristic Value succeeded.
     
     An Error Response shall be sent by the server in response to the Write Request if insufficient authentication, insufficient authorization, insufficient encryption key size is used by the client, or if a write operation is not permitted on the Characteristic Value. The Error Code parameter is set as specified in the Attribute Protocol. If the Characteristic Value that is written is the wrong size, or has an invalid value as defined by the profile, then the value shall not be written and an Error Response shall be sent with the Error Code set to Application Error by the server.
     */
    private func writeResponse(_ response: ATTResponse<ATTWriteResponse>, completion: (GATTClientResponse<()>) -> ()) {
        
        switch response {
        case let .failure(error):
            completion(.failure(.errorResponse(error)))
        case .success: // PDU contains no data
            completion(.success(()))
        }
    }
    
    /**
     Prepare Write Response
     
     An Error Response shall be sent by the server in response to the Prepare Write Request if insufficient authentication, insufficient authorization, insufficient encryption key size is used by the client, or if a write operation is not permitted on the Characteristic Value. The Error Code parameter is set as specified in the Attribute Protocol. If the Attribute Value that is written is the wrong size, or has an invalid value as defined by the profile, then the write shall not succeed and an Error Response shall be sent with the Error Code set to Application Error by the server.
     */
    private func prepareWriteResponse(_ response: ATTResponse<ATTPrepareWriteResponse>, operation: WriteOperation) async throws {
        
        @inline(__always)
        func complete(_ completion: (WriteOperation) -> ()) {
            inLongWrite = false
            completion(operation)
        }
        
        switch response {
        case let .failure(error):
            complete { $0.failure(error) }
        case let .success(pdu):
            operation.receivedData += pdu.partValue
            
            // verify data sent
            if operation.reliableWrites {
                
                guard pdu.handle == operation.lastRequest.handle,
                    pdu.offset == operation.lastRequest.offset,
                    pdu.partValue == operation.lastRequest.partValue
                    else { complete { $0.completion(.failure(GATTClientError.invalidResponse(pdu))) }; return }
            }
            
            let offset = Int(operation.lastRequest.offset) + operation.lastRequest.partValue.count
            
            if offset < operation.data.count {
                
                // write next part
                let maxLength = await Int(maximumTransmissionUnit.rawValue) - 5
                let endIndex = min(offset + maxLength, operation.data.count)
                let attributeValuePart = operation.data.subdataNoCopy(in: offset ..< endIndex)
                
                let request = ATTPrepareWriteRequest(
                    handle: operation.lastRequest.handle,
                    offset: UInt16(offset),
                    partValue: attributeValuePart
                )
                
                operation.lastRequest = request
                operation.sentData += attributeValuePart
                
                let response = try await send(request, response: ATTPrepareWriteResponse.self)
                try await self.prepareWriteResponse(response, operation: operation)
                
            } else {
                
                assert(offset == operation.data.count)
                assert(operation.receivedData == operation.sentData)
                
                // all data sent
                let request = ATTExecuteWriteRequest.write
                let response = try await send(request, response: ATTExecuteWriteResponse.self)
                self.executeWriteResponse(response, operation: operation)
            }
        }
    }
    
    private func executeWriteResponse(_ response: ATTResponse<ATTExecuteWriteResponse>, operation: WriteOperation) {
        
        func complete(_ completion: (WriteOperation) -> ()) {
            inLongWrite = false
            completion(operation)
        }
        
        switch response {
        case let .failure(error):
            complete { $0.failure(error) }
        case .success:
            complete { $0.success() }
        }
    }
    
    private func notification(_ notification: ATTHandleValueNotification) {
        notifications[notification.handle]?(notification.value)
    }
    
    private func indication(_ indication: ATTHandleValueIndication) async {
        let confirmation = ATTHandleValueConfirmation()
        // send acknowledgement
        do { try await send(confirmation) }
        catch { log?("Unable to send indication confirmation. \(error)") }
        indications[indication.handle]?(indication.value)
    }
}

// MARK: - Supporting Types

public extension GATTClient {
    
    typealias Error = GATTClientError
        
    typealias Notification = (Data) -> ()
}

public enum GATTClientError: Error {
    
    /// The GATT server responded with an error response.
    case errorResponse(ATTErrorResponse)
    
    /// The GATT server responded with a PDU that has invalid values.
    case invalidResponse(ATTProtocolDataUnit)
    
    /// Already writing long value.
    case inLongWrite
    
    /// Characteristic missing client configuration descriptor.
    case clientCharacteristicConfigurationNotAllowed(GATTClient.Characteristic)
}

// MARK: CustomNSError

#if canImport(Darwin)

extension GATTClientError: CustomNSError {
    
    public enum UserInfoKey: String {
        
        case response = "org.pureswift.Bluetooth.GATTClientError.response"
        case characteristic = "org.pureswift.Bluetooth.GATTClientError.characteristic"
    }
    
    public static var errorDomain: String {
        return "org.pureswift.Bluetooth.GATTClientError"
    }
    
    public var errorUserInfo: [String: Any] {
        
        var userInfo = [String: Any]()
        
        switch self {
            
        case let .errorResponse(response):
            
            userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(
                "GATT Server responded with an error response (\(response.error)).",
                comment: "org.pureswift.Bluetooth.GATTClientError.errorResponse"
            )
            userInfo[NSUnderlyingErrorKey] = response as NSError
            userInfo[UserInfoKey.response.rawValue] = response
            
        case let .invalidResponse(response):
            
            userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(
                "GATT Server responded with an invalid response (\(type(of: response).attributeOpcode).",
                comment: "org.pureswift.Bluetooth.GATTClientError.invalidResponse"
            )
            userInfo[UserInfoKey.response.rawValue] = response
            
        case .inLongWrite:
            
            userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(
                "GATT Client already in long write.",
                comment: "org.pureswift.Bluetooth.GATTClientError.inLongWrite"
            )
            
        case let .clientCharacteristicConfigurationNotAllowed(characteristic):
            
            userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(
                "Characteristic \(characteristic.uuid) doesn't allow for client characteristic configuration.",
                comment: "org.pureswift.Bluetooth.GATTClientError.clientCharacteristicConfigurationNotAllowed"
            )
            userInfo[UserInfoKey.characteristic.rawValue] = characteristic
        }
        
        return userInfo
    }
}

#endif

internal typealias GATTClientResponse <Value> = Result<Value, GATTClientError>

public extension GATTClient {
    
    /// A discovered service.
    struct Service {
        
        public let uuid: BluetoothUUID
        
        public let isPrimary: Bool
        
        public let handle: UInt16
        
        public let end: UInt16
    }
    
    /// A discovered characteristic.
    struct Characteristic {
        
        public typealias Property = GATTCharacteristicProperty
        
        public let uuid: BluetoothUUID
        
        public let properties: BitMaskOptionSet<Property>
        
        public let handle: (declaration: UInt16, value: UInt16)
    }
    
    /// A discovered descriptor
    struct Descriptor {
        
        public let uuid: BluetoothUUID
        
        public let handle: UInt16
    }
}

// MARK: - Private Supporting Types

fileprivate final class DiscoveryOperation <T> {
    
    let uuid: BluetoothUUID?
    
    var start: UInt16 {
        
        didSet { assert(start <= end, "Start Handle should always be less than or equal to End handle") }
    }
    
    let end: UInt16
    
    let type: GATTUUID
    
    var foundData = [T]()
    
    let completion: (GATTClientResponse<[T]>) -> ()
    
    init(uuid: BluetoothUUID?,
         start: UInt16,
         end: UInt16,
         type: GATTUUID,
         completion: @escaping (GATTClientResponse<[T]>) -> ()) {
        
        self.uuid = uuid
        self.start = start
        self.end = end
        self.type = type
        self.completion = completion
    }
    
    @inline(__always)
    func success() {
        completion(.success(foundData))
    }
    
    @inline(__always)
    func failure(_ responseError: ATTErrorResponse) {
        if responseError.error == .attributeNotFound {
            success()
        } else {
            completion(.failure(GATTClientError.errorResponse(responseError)))
        }
    }
}

private extension GATTClient {
    
    final class DescriptorDiscoveryOperation {
        
        var start: UInt16 {
            
            didSet { assert(start <= end, "Start Handle should always be less than or equal to End handle") }
        }
        
        let end: UInt16
        
        var foundDescriptors = [Descriptor]()
        
        let completion: (GATTClientResponse<[Descriptor]>) -> ()
        
        init(start: UInt16,
             end: UInt16,
             completion: @escaping (GATTClientResponse<[Descriptor]>) -> ()) {
            
            self.start = start
            self.end = end
            self.completion = completion
        }
        
        @inline(__always)
        func success() {
            
            completion(.success(foundDescriptors))
        }
        
        @inline(__always)
        func failure(_ responseError: ATTErrorResponse) {
            
            if responseError.error == .attributeNotFound {
                
                success()
                
            } else {
                
                completion(.failure(GATTClientError.errorResponse(responseError)))
            }
        }
    }
    
    final class ReadOperation {
        
        let handle: UInt16
        
        var data = Data()
        
        let completion: (GATTClientResponse<Data>) -> ()
        
        var offset: UInt16 {
            
            @inline(__always)
            get { return UInt16(data.count) }
        }
        
        init(handle: UInt16,
             completion: @escaping (GATTClientResponse<Data>) -> ()) {
            
            self.handle = handle
            self.completion = completion
        }
        
        @inline(__always)
        func success() {
            
            completion(.success(data))
        }
        
        @inline(__always)
        func failure(_ responseError: ATTErrorResponse) {
            
            if responseError.error == .invalidOffset,
                data.isEmpty == false {
                
                success()
                
            } else {
                
                completion(.failure(GATTClientError.errorResponse(responseError)))
            }
        }
    }
    
    final class ReadMultipleOperation {
        
        let characteristics: [Characteristic]
        
        let completion: (GATTClientResponse<Data>) -> ()
        
        init(characteristics: [Characteristic],
             completion: @escaping (GATTClientResponse<Data>) -> ()) {
            
            self.characteristics = characteristics
            self.completion = completion
        }
        
        @inline(__always)
        func success(_ values: Data) {
            completion(.success(values))
        }
        
        @inline(__always)
        func failure(_ responseError: ATTErrorResponse) {
            completion(.failure(GATTClientError.errorResponse(responseError)))
        }
    }
    
    final class ReadUsingUUIDOperation {
        
        let uuid: BluetoothUUID
        
        let completion: (GATTClientResponse<[UInt16: Data]>) -> ()
        
        init(uuid: BluetoothUUID,
             completion: @escaping (GATTClientResponse<[UInt16: Data]>) -> ()) {
            
            self.uuid = uuid
            self.completion = completion
        }
        
        func success(_ attributes: [ATTReadByTypeResponse.AttributeData]) {
            
            var data = [UInt16: Data](minimumCapacity: attributes.count)
            
            for attribute in attributes {
                data[attribute.handle] = Data(attribute.value)
            }
            
            completion(.success(data))
        }
        
        func failure(_ responseError: ATTErrorResponse) {
            
            completion(.failure(GATTClientError.errorResponse(responseError)))
        }
    }
    
    final class WriteOperation {
        
        typealias Completion = (GATTClientResponse<Void>) -> ()
        
        let handle: UInt16
        
        let completion: Completion
        
        let reliableWrites: Bool
        
        let data: Data
        
        var sentData: Data
        
        var receivedData: Data
        
        var lastRequest: ATTPrepareWriteRequest
        
        init(handle: UInt16,
             data: Data,
             reliableWrites: Bool,
             lastRequest: ATTPrepareWriteRequest,
             completion: @escaping Completion) {
            
            precondition(data.isEmpty == false)
            
            self.handle = handle
            self.completion = completion
            self.data = data
            self.reliableWrites = reliableWrites
            self.lastRequest = lastRequest
            self.sentData = lastRequest.partValue
            self.receivedData = Data()
        }
        
        @inline(__always)
        func success() {
            completion(.success(()))
        }
        
        @inline(__always)
        func failure(_ responseError: ATTErrorResponse) {
            completion(.failure(GATTClientError.errorResponse(responseError)))
        }
    }
}
