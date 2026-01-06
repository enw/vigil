import Foundation

class HistoryManager: ObservableObject {
    private var cpuHistory: RingBuffer<Double>
    private var memoryHistory: RingBuffer<Double>
    private var timestamps: RingBuffer<Date>
    private let maxHistoryPoints = 3600 // 1 hour at 1-second intervals
    private let lock = NSLock()

    init() {
        self.cpuHistory = RingBuffer(capacity: maxHistoryPoints)
        self.memoryHistory = RingBuffer(capacity: maxHistoryPoints)
        self.timestamps = RingBuffer(capacity: maxHistoryPoints)
    }

    func addDataPoint(cpuUsage: Double, memoryUsage: Double) {
        lock.lock()
        defer { lock.unlock() }
        cpuHistory.append(cpuUsage)
        memoryHistory.append(memoryUsage)
        timestamps.append(Date())
    }

    func getCPUHistory() -> [Double] {
        cpuHistory.elements
    }

    func getMemoryHistory() -> [Double] {
        memoryHistory.elements
    }

    func getTimestamps() -> [Date] {
        timestamps.elements
    }

    func getLastNDataPoints(_ n: Int) -> (cpu: [Double], memory: [Double], timestamps: [Date]) {
        let count = min(n, cpuHistory.count)
        let startIndex = max(0, cpuHistory.count - count)

        let cpu = Array(cpuHistory.elements.dropFirst(startIndex))
        let memory = Array(memoryHistory.elements.dropFirst(startIndex))
        let times = Array(timestamps.elements.dropFirst(startIndex))

        return (cpu, memory, times)
    }

    func clearHistory() {
        cpuHistory = RingBuffer(capacity: maxHistoryPoints)
        memoryHistory = RingBuffer(capacity: maxHistoryPoints)
        timestamps = RingBuffer(capacity: maxHistoryPoints)
    }
}

// MARK: - Ring Buffer
class RingBuffer<T> {
    private var buffer: [T?]
    private var writeIndex = 0
    var count = 0
    let capacity: Int

    init(capacity: Int) {
        self.capacity = capacity
        self.buffer = Array(repeating: nil, count: capacity)
    }

    func append(_ element: T) {
        buffer[writeIndex] = element
        writeIndex = (writeIndex + 1) % capacity
        count = min(count + 1, capacity)
    }

    var elements: [T] {
        var result: [T] = []
        let actualCount = count
        let startIndex = count < capacity ? 0 : writeIndex

        for i in 0..<actualCount {
            let index = (startIndex + i) % capacity
            if let element = buffer[index] {
                result.append(element)
            }
        }
        return result
    }

    func clear() {
        buffer = Array(repeating: nil, count: capacity)
        writeIndex = 0
        count = 0
    }
}
