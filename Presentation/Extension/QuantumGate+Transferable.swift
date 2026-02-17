import CoreTransferable
import UniformTypeIdentifiers

extension QuantumGate: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .quantumGate)
    }
}

extension UTType {
    static var quantumGate: UTType {
        UTType(exportedAs: "com.quantumgate.gate")
    }
}
