public enum BasicCodingKey: CodingKey {
    case string(String)
    case int(Int)
    
    public var stringValue: String {
        switch self {
        case .string(let string): return string
        case .int(let int): return int.description
        }
    }
    
    public init?(stringValue: String) {
        self = .string(stringValue)
    }
    
    public var intValue: Int? {
        switch self {
        case .int(let int): return int
        case .string:
            #warning("Consider adding String -> Int conversion")
            return nil
        }
    }
    
    public init?(intValue: Int) {
        self = .int(intValue)
    }
}
