import Foundation

/// HID++ 2.0 Thumbwheel (0x2150) — thumb wheel reporting and inversion.
///
/// Functions:
///   0: getInfo()       -> resolutions, default direction, capabilities
///   1: getConfig()     -> current reporting status
///   2: setConfig()     -> set reporting status
enum ThumbWheelFeature {

    static let featureId: UInt16 = 0x2150

    // MARK: - Info

    struct ThumbWheelInfo: Sendable {
        /// Native resolution (counts per revolution).
        let nativeResolution: Int
        /// Diverted counts per revolution.
        let divertedResolution: Int
        /// Direction inversion is part of the reporting status for this feature.
        let supportsInversion: Bool
        /// Whether touch detection is supported.
        let supportsTouch: Bool
        /// Whether timestamp reporting is supported.
        let supportsTimestamp: Bool
    }

    // MARK: - Config

    struct ThumbWheelConfig: Sendable {
        /// Whether thumb wheel direction is inverted.
        let inverted: Bool
        /// Whether thumb wheel is diverted to software.
        let diverted: Bool
    }

    // MARK: - Function 0: GetInfo

    /// Get thumb wheel capabilities.
    ///
    /// Response:
    ///   param[0..1]: native resolution (big-endian)
    ///   param[2..3]: diverted resolution (big-endian)
    ///   param[4]: default direction
    ///   param[5]: capability flags
    static func getInfo(
        transport: HIDTransport,
        deviceIndex: UInt8,
        featureIndex: UInt8
    ) async throws -> ThumbWheelInfo {
        let response = try await transport.send(
            deviceIndex: deviceIndex,
            featureIndex: featureIndex,
            functionId: 0x00,
            softwareId: 0x01
        )

        let params = response.params
        let nativeRes = (Int(params[0]) << 8) | Int(params[1])
        let divertedRes = params.count > 3 ? (Int(params[2]) << 8) | Int(params[3]) : nativeRes
        let flags = params.count > 5 ? params[5] : 0

        return ThumbWheelInfo(
            nativeResolution: nativeRes,
            divertedResolution: divertedRes,
            supportsInversion: true,
            supportsTouch: (flags & 0x02) != 0,
            supportsTimestamp: (flags & 0x01) != 0
        )
    }

    // MARK: - Function 1: GetConfig

    /// Get current thumb wheel configuration (inversion, divert).
    ///
    /// Response:
    ///   param[0]: diverted
    ///   param[1]: status flags (bit 0 = inverted)
    static func getConfig(
        transport: HIDTransport,
        deviceIndex: UInt8,
        featureIndex: UInt8
    ) async throws -> ThumbWheelConfig {
        let response = try await transport.send(
            deviceIndex: deviceIndex,
            featureIndex: featureIndex,
            functionId: 0x01,
            softwareId: 0x01
        )

        return ThumbWheelConfig(
            inverted: response.params.count > 1 && (response.params[1] & 0x01) != 0,
            diverted: response.params[0] != 0
        )
    }

    // MARK: - Function 2: SetConfig

    /// Set thumb wheel configuration.
    ///
    /// - Parameters:
    ///   - inverted: Whether to invert direction.
    ///   - diverted: Whether to divert to software.
    static func setConfig(
        transport: HIDTransport,
        deviceIndex: UInt8,
        featureIndex: UInt8,
        inverted: Bool,
        diverted: Bool
    ) async throws {
        let _ = try await transport.send(
            deviceIndex: deviceIndex,
            featureIndex: featureIndex,
            functionId: 0x02,
            softwareId: 0x01,
            params: [diverted ? 1 : 0, inverted ? 1 : 0]
        )
    }
}
