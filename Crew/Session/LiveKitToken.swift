import CryptoKit
import Foundation

enum LiveKitToken {
    static func mint(
        apiKey: String,
        apiSecret: String,
        identity: String,
        name: String,
        room: String,
        ttl: TimeInterval = 60 * 60 * 24
    ) throws -> String {
        let now = Date().timeIntervalSince1970
        let payload: [String: Any] = [
            "iss": apiKey,
            "sub": identity,
            "name": name,
            "nbf": Int(now) - 10,
            "exp": Int(now + ttl),
            "video": [
                "roomJoin": true,
                "room": room,
                "canPublish": true,
                "canSubscribe": true,
                "canPublishData": true,
            ],
        ]

        let header = try encodeJSON(["alg": "HS256", "typ": "JWT"])
        let body = try encodeJSON(payload)
        let unsigned = "\(header).\(body)"
        let key = SymmetricKey(data: Data(apiSecret.utf8))
        let mac = HMAC<SHA256>.authenticationCode(for: Data(unsigned.utf8), using: key)
        return "\(unsigned).\(Data(mac).base64URLEncoded())"
    }

    private static func encodeJSON(_ object: [String: Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: object, options: [])
        return data.base64URLEncoded()
    }
}

private extension Data {
    func base64URLEncoded() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
