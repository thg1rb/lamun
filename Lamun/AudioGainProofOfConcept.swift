#if DEBUG
  import AudioToolbox
  import Combine
  import CoreAudio
  import Foundation
  import Synchronization

  @available(macOS 15.0, *)
  @MainActor
  final class AudioGainProofOfConcept: ObservableObject {
    @Published private(set) var activeSessions: [AudioObjectID: AudioGainSessionInfo] = [:]
    @Published private(set) var lastError: String?
    @Published var selectedMuteBehaviorRawValue = CATapMuteBehavior.mutedWhenTapped.rawValue

    private var sessionResources: [AudioObjectID: AudioGainTapSession] = [:]

    func isActive(processObjectID: AudioObjectID) -> Bool {
      sessionResources[processObjectID] != nil
    }

    func gain(for processObjectID: AudioObjectID) -> Double {
      sessionResources[processObjectID]?.gain ?? 1
    }

    func start(_ process: AudioProcessSnapshot) {
      guard sessionResources[process.audioObjectID] == nil else { return }
      guard process.isConnectedToHAL, process.processIdentifier > 0 else {
        lastError =
          "The selected process is no longer connected to Core Audio. Refresh discovery and try again."
        return
      }
      do {
        let behavior = CATapMuteBehavior(rawValue: selectedMuteBehaviorRawValue) ?? .mutedWhenTapped
        let session = try AudioGainTapSession.start(process: process, muteBehavior: behavior)
        sessionResources[process.audioObjectID] = session
        activeSessions[process.audioObjectID] = AudioGainSessionInfo(
          streamFormatDescription: session.streamFormatDescription,
          outputDeviceName: session.outputDeviceName,
          muteBehaviorName: session.muteBehaviorName
        )
        lastError = nil
      } catch {
        lastError = error.localizedDescription
      }
    }

    func setGain(_ value: Double, for processObjectID: AudioObjectID) {
      sessionResources[processObjectID]?.setGain(value)
    }

    func stop(processObjectID: AudioObjectID) {
      guard let session = sessionResources[processObjectID] else { return }
      do {
        try session.stop()
        sessionResources.removeValue(forKey: processObjectID)
        activeSessions.removeValue(forKey: processObjectID)
        lastError = nil
      } catch {
        lastError = error.localizedDescription
      }
    }

    func stopAll() {
      for processObjectID in Array(sessionResources.keys) {
        stop(processObjectID: processObjectID)
      }
    }

    func reconcile(with snapshots: [AudioProcessSnapshot]) {
      let connectedIDs = Set(snapshots.filter(\.isConnectedToHAL).map(\.audioObjectID))
      for processObjectID in Array(sessionResources.keys)
      where !connectedIDs.contains(processObjectID) {
        stop(processObjectID: processObjectID)
      }
    }

    func metrics(for processObjectID: AudioObjectID) -> AudioGainMetricSnapshot? {
      sessionResources[processObjectID]?.metrics.snapshot()
    }
  }

  struct AudioGainSessionInfo: Equatable {
    let streamFormatDescription: String
    let outputDeviceName: String
    let muteBehaviorName: String
  }

  @available(macOS 15.0, *)
  @MainActor
  private final class AudioGainTapSession {
    let streamFormatDescription: String
    let outputDeviceName: String
    let muteBehaviorName: String
    let metrics: AudioGainMetricCollector
    private var tapID: AudioObjectID?
    private var aggregateDeviceID: AudioObjectID?
    private var ioProcID: AudioDeviceIOProcID?
    private let gainControl: AudioGainControl
    private var ioProcIsRunning = false
    private(set) var gain = 1.0

    private init(
      tapID: AudioObjectID,
      aggregateDeviceID: AudioObjectID,
      ioProcID: AudioDeviceIOProcID,
      gainControl: AudioGainControl,
      metrics: AudioGainMetricCollector,
      outputDeviceName: String,
      muteBehaviorName: String
    ) {
      self.tapID = tapID
      self.aggregateDeviceID = aggregateDeviceID
      self.ioProcID = ioProcID
      self.ioProcIsRunning = true
      self.gainControl = gainControl
      self.metrics = metrics
      self.outputDeviceName = outputDeviceName
      self.muteBehaviorName = muteBehaviorName
      self.streamFormatDescription = "HAL aggregate callback; Float32 buffers required by this POC"
    }

    static func start(
      process: AudioProcessSnapshot,
      muteBehavior: CATapMuteBehavior
    ) throws -> AudioGainTapSession {
      let description = CATapDescription(stereoMixdownOfProcesses: [process.audioObjectID])
      description.name = "Lamun W003 gain POC · \(process.displayName)"
      description.isPrivate = true
      description.muteBehavior = muteBehavior

      var tapID = AudioObjectID(kAudioObjectUnknown)
      let tapStatus = AudioHardwareCreateProcessTap(description, &tapID)
      guard tapStatus == noErr else {
        throw AudioGainProofOfConceptError.coreAudio("Create process tap", status: tapStatus)
      }

      var aggregateID: AudioObjectID = 0
      var ioProcID: AudioDeviceIOProcID?
      do {
        let output = try defaultOutputDevice()
        let tapUID = try tapUID(for: tapID)
        let aggregateDescription: [String: Any] = [
          kAudioAggregateDeviceNameKey: "Lamun W003 · \(process.displayName)",
          kAudioAggregateDeviceUIDKey: "org.example.lamun.w003.\(UUID().uuidString)",
          kAudioAggregateDeviceIsPrivateKey: 1,
          kAudioAggregateDeviceIsStackedKey: 0,
          kAudioAggregateDeviceSubDeviceListKey: [[kAudioSubDeviceUIDKey: output.uid]],
          kAudioAggregateDeviceMainSubDeviceKey: output.uid,
          kAudioAggregateDeviceTapListKey: [[kAudioSubTapUIDKey: tapUID]],
          kAudioAggregateDeviceTapAutoStartKey: 1,
        ]
        let aggregateStatus = AudioHardwareCreateAggregateDevice(
          aggregateDescription as CFDictionary,
          &aggregateID
        )
        guard aggregateStatus == noErr else {
          throw AudioGainProofOfConceptError.coreAudio(
            "Create tap/output aggregate device", status: aggregateStatus)
        }

        let tapFormat = try audioStreamFormat(
          objectID: tapID,
          selector: kAudioTapPropertyFormat,
          scope: kAudioObjectPropertyScopeGlobal,
          label: "Read process tap stream format"
        )
        try requireFloat32(tapFormat, label: "Process tap")

        let outputFormat = try audioStreamFormat(
          objectID: aggregateID,
          selector: kAudioDevicePropertyStreamFormat,
          scope: kAudioDevicePropertyScopeOutput,
          label: "Read aggregate output stream format"
        )
        try requireFloat32(outputFormat, label: "Aggregate output")

        let metrics = AudioGainMetricCollector()
        let gainControl = AudioGainControl()
        let ioBlock = makeAudioGainIOBlock(metrics: metrics, gainControl: gainControl)
        let procStatus = AudioDeviceCreateIOProcIDWithBlock(&ioProcID, aggregateID, nil, ioBlock)
        guard procStatus == noErr, let ioProcID else {
          throw AudioGainProofOfConceptError.coreAudio(
            "Create aggregate I/O callback", status: procStatus)
        }
        let startStatus = AudioDeviceStart(aggregateID, ioProcID)
        guard startStatus == noErr else {
          throw AudioGainProofOfConceptError.coreAudio(
            "Start aggregate I/O callback", status: startStatus)
        }
        return AudioGainTapSession(
          tapID: tapID,
          aggregateDeviceID: aggregateID,
          ioProcID: ioProcID,
          gainControl: gainControl,
          metrics: metrics,
          outputDeviceName: output.name,
          muteBehaviorName: name(for: muteBehavior)
        )
      } catch {
        if let ioProcID {
          AudioDeviceStop(aggregateID, ioProcID)
          AudioDeviceDestroyIOProcID(aggregateID, ioProcID)
        }
        if aggregateID != 0 {
          let status = AudioHardwareDestroyAggregateDevice(aggregateID)
          if status != noErr { NSLog("W003 POC aggregate cleanup failed: 0x%08x", status) }
        }
        let destroyStatus = AudioHardwareDestroyProcessTap(tapID)
        if destroyStatus != noErr { NSLog("W003 POC tap cleanup failed: 0x%08x", destroyStatus) }
        throw error
      }
    }

    func setGain(_ value: Double) {
      let normalized = AudioGainValue.normalized(value)
      gain = normalized
      gainControl.set(normalized)
    }

    func stop() throws {
      var failures: [AudioGainProofOfConceptError] = []
      if let aggregateDeviceID {
        if let ioProcID {
          if ioProcIsRunning {
            let status = AudioDeviceStop(aggregateDeviceID, ioProcID)
            if status == noErr {
              ioProcIsRunning = false
            } else {
              failures.append(.coreAudio("Stop aggregate I/O callback", status: status))
            }
          }
          if !ioProcIsRunning {
            let status = AudioDeviceDestroyIOProcID(aggregateDeviceID, ioProcID)
            if status == noErr {
              self.ioProcID = nil
            } else {
              failures.append(.coreAudio("Destroy aggregate I/O callback", status: status))
            }
          }
        }
        if ioProcID == nil {
          let status = AudioHardwareDestroyAggregateDevice(aggregateDeviceID)
          if status == noErr {
            self.aggregateDeviceID = nil
          } else {
            failures.append(.coreAudio("Destroy aggregate device", status: status))
          }
        }
      }
      if aggregateDeviceID == nil, let tapID {
        let status = AudioHardwareDestroyProcessTap(tapID)
        if status == noErr {
          self.tapID = nil
        } else {
          failures.append(.coreAudio("Destroy process tap", status: status))
        }
      }
      if !failures.isEmpty {
        throw AudioGainProofOfConceptError.cleanup(failures.map(\.localizedDescription))
      }
    }

    private static func tapUID(for tapID: AudioObjectID) throws -> String {
      var address = AudioObjectPropertyAddress(
        mSelector: kAudioTapPropertyUID,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
      )
      var size = UInt32(MemoryLayout<CFString>.size)
      var uid: CFString = "" as CFString
      let status = withUnsafeMutablePointer(to: &uid) { pointer in
        AudioObjectGetPropertyData(tapID, &address, 0, nil, &size, pointer)
      }
      guard status == noErr else {
        throw AudioGainProofOfConceptError.coreAudio("Read process tap UID", status: status)
      }
      return uid as String
    }

    private static func audioStreamFormat(
      objectID: AudioObjectID,
      selector: AudioObjectPropertySelector,
      scope: AudioObjectPropertyScope,
      label: String
    ) throws -> AudioStreamBasicDescription {
      var address = AudioObjectPropertyAddress(
        mSelector: selector,
        mScope: scope,
        mElement: kAudioObjectPropertyElementMain
      )
      var size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
      var format = AudioStreamBasicDescription()
      let status = withUnsafeMutablePointer(to: &format) { pointer in
        AudioObjectGetPropertyData(objectID, &address, 0, nil, &size, pointer)
      }
      guard status == noErr else {
        throw AudioGainProofOfConceptError.coreAudio(label, status: status)
      }
      return format
    }

    private static func requireFloat32(
      _ format: AudioStreamBasicDescription,
      label: String
    ) throws {
      let isLinearPCM = format.mFormatID == kAudioFormatLinearPCM
      let isFloat32 =
        format.mBitsPerChannel == 32
        && format.mFormatFlags & kAudioFormatFlagIsFloat != 0
      guard isLinearPCM && isFloat32 else {
        throw AudioGainProofOfConceptError.unsupportedFormat(
          "\(label) must be linear PCM Float32; received formatID \(format.mFormatID), flags 0x\(String(format.mFormatFlags, radix: 16)), bits/channel \(format.mBitsPerChannel)."
        )
      }
    }

    private static func defaultOutputDevice() throws -> (
      id: AudioDeviceID, uid: String, name: String
    ) {
      var address = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
      )
      var size = UInt32(MemoryLayout<AudioDeviceID>.size)
      var deviceID = AudioDeviceID(kAudioObjectUnknown)
      let status = AudioObjectGetPropertyData(
        AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID)
      guard status == noErr, deviceID != kAudioObjectUnknown else {
        throw AudioGainProofOfConceptError.coreAudio("Read default output device", status: status)
      }
      func stringProperty(_ selector: AudioObjectPropertySelector, label: String) throws -> String {
        var property = AudioObjectPropertyAddress(
          mSelector: selector,
          mScope: kAudioObjectPropertyScopeGlobal,
          mElement: kAudioObjectPropertyElementMain
        )
        var propertySize = UInt32(MemoryLayout<CFString>.size)
        var value: CFString = "" as CFString
        let result = withUnsafeMutablePointer(to: &value) { pointer in
          AudioObjectGetPropertyData(deviceID, &property, 0, nil, &propertySize, pointer)
        }
        guard result == noErr else {
          throw AudioGainProofOfConceptError.coreAudio(label, status: result)
        }
        return value as String
      }
      return (
        deviceID,
        try stringProperty(kAudioDevicePropertyDeviceUID, label: "Read output device UID"),
        try stringProperty(kAudioObjectPropertyName, label: "Read output device name")
      )
    }

    private static func name(for behavior: CATapMuteBehavior) -> String {
      switch behavior {
      case .unmuted: "Unmuted (expected duplicate output)"
      case .muted: "Muted"
      case .mutedWhenTapped: "Muted while the tap is read"
      @unknown default: "Unknown behavior (\(behavior.rawValue))"
      }
    }
  }

  @available(macOS 15.0, *)
  private func makeAudioGainIOBlock(
    metrics: AudioGainMetricCollector,
    gainControl: AudioGainControl
  ) -> AudioDeviceIOBlock {
    { _, inputData, inputTime, outputData, outputTime in
      metrics.process(
        inputData: inputData,
        inputHostTime: inputTime.pointee.mHostTime,
        outputData: outputData,
        outputHostTime: outputTime.pointee.mHostTime,
        gainControl: gainControl
      )
    }
  }

  @available(macOS 15.0, *)
  private final class AudioGainMetricCollector: @unchecked Sendable {
    private static let latencyCapacity = 2_048
    private let inputRMSBits = Atomic<UInt64>(0)
    private let outputRMSBits = Atomic<UInt64>(0)
    private let callbackCount = Atomic<UInt64>(0)
    private let inputBufferCount = Atomic<UInt64>(0)
    private let outputBufferCount = Atomic<UInt64>(0)
    private let inputBufferBytes = Atomic<UInt64>(0)
    private let outputBufferBytes = Atomic<UInt64>(0)
    private let inputChannels = Atomic<UInt64>(0)
    private let outputChannels = Atomic<UInt64>(0)
    private let latencyWriteCount = Atomic<UInt64>(0)
    private let latencySamples: UnsafeMutablePointer<Atomic<UInt64>>

    init() {
      let storage = UnsafeMutablePointer<Atomic<UInt64>>.allocate(capacity: Self.latencyCapacity)
      for index in 0..<Self.latencyCapacity {
        storage.advanced(by: index).initialize(to: Atomic<UInt64>(0))
      }
      latencySamples = storage
    }

    deinit {
      latencySamples.deinitialize(count: Self.latencyCapacity)
      latencySamples.deallocate()
    }

    func process(
      inputData: UnsafePointer<AudioBufferList>,
      inputHostTime: UInt64,
      outputData: UnsafeMutablePointer<AudioBufferList>,
      outputHostTime: UInt64,
      gainControl: AudioGainControl
    ) {
      let input = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: inputData))
      let output = UnsafeMutableAudioBufferListPointer(outputData)
      callbackCount.wrappingAdd(1, ordering: .relaxed)
      inputBufferCount.store(UInt64(input.count), ordering: .relaxed)
      outputBufferCount.store(UInt64(output.count), ordering: .relaxed)
      inputBufferBytes.store(input.first.map { UInt64($0.mDataByteSize) } ?? 0, ordering: .relaxed)
      outputBufferBytes.store(
        output.first.map { UInt64($0.mDataByteSize) } ?? 0, ordering: .relaxed)
      inputChannels.store(input.first.map { UInt64($0.mNumberChannels) } ?? 0, ordering: .relaxed)
      outputChannels.store(output.first.map { UInt64($0.mNumberChannels) } ?? 0, ordering: .relaxed)
      let gain = gainControl.value
      var inputSquares = 0.0
      var outputSquares = 0.0
      var samples = 0

      for outputIndex in 0..<output.count {
        let outputBuffer = output[outputIndex]
        guard let outputPointer = outputBuffer.mData?.assumingMemoryBound(to: Float.self) else {
          continue
        }
        let outputCount = Int(outputBuffer.mDataByteSize) / MemoryLayout<Float>.size
        guard outputIndex < input.count else {
          outputPointer.update(repeating: 0, count: outputCount)
          continue
        }
        let inputBuffer = input[outputIndex]
        guard
          inputBuffer.mNumberChannels == outputBuffer.mNumberChannels,
          let inputPointer = inputBuffer.mData?.assumingMemoryBound(to: Float.self)
        else {
          outputPointer.update(repeating: 0, count: outputCount)
          continue
        }
        let inputCount = Int(inputBuffer.mDataByteSize) / MemoryLayout<Float>.size
        let count = min(inputCount, outputCount)
        for sampleIndex in 0..<count {
          let inputSample = inputPointer[sampleIndex]
          let outputSample = inputSample * Float(gain)
          outputPointer[sampleIndex] = outputSample
          let inputValue = Double(inputSample)
          let outputValue = Double(outputSample)
          inputSquares += inputValue * inputValue
          outputSquares += outputValue * outputValue
        }
        if count < outputCount {
          outputPointer.advanced(by: count).update(repeating: 0, count: outputCount - count)
        }
        samples += count
      }
      if samples > 0 {
        inputRMSBits.store(sqrt(inputSquares / Double(samples)).bitPattern, ordering: .relaxed)
        outputRMSBits.store(sqrt(outputSquares / Double(samples)).bitPattern, ordering: .relaxed)
      }
      if inputHostTime > 0, outputHostTime >= inputHostTime {
        let nanos = AudioConvertHostTimeToNanos(outputHostTime - inputHostTime)
        if nanos > 0 {
          let index = latencyWriteCount.load(ordering: .relaxed)
          latencySamples[Int(index % UInt64(Self.latencyCapacity))].store(nanos, ordering: .relaxed)
          latencyWriteCount.store(index + 1, ordering: .relaxed)
        }
      }
    }

    func snapshot() -> AudioGainMetricSnapshot {
      let count = min(latencyWriteCount.load(ordering: .relaxed), UInt64(Self.latencyCapacity))
      let values = (0..<Int(count)).map { latencySamples[$0].load(ordering: .relaxed) }
        .filter { $0 > 0 }
        .sorted()
      return AudioGainMetricSnapshot(
        inputRMS: Double(bitPattern: inputRMSBits.load(ordering: .relaxed)),
        postGainRMS: Double(bitPattern: outputRMSBits.load(ordering: .relaxed)),
        callbackCount: callbackCount.load(ordering: .relaxed),
        inputBufferCount: inputBufferCount.load(ordering: .relaxed),
        outputBufferCount: outputBufferCount.load(ordering: .relaxed),
        inputBufferBytes: inputBufferBytes.load(ordering: .relaxed),
        outputBufferBytes: outputBufferBytes.load(ordering: .relaxed),
        inputChannels: inputChannels.load(ordering: .relaxed),
        outputChannels: outputChannels.load(ordering: .relaxed),
        callbackLatencyP50Milliseconds: Self.percentile(values, fraction: 0.50),
        callbackLatencyP95Milliseconds: Self.percentile(values, fraction: 0.95),
        callbackLatencyMaximumMilliseconds: values.last.map { Double($0) / 1_000_000 }
      )
    }

    private static func percentile(_ values: [UInt64], fraction: Double) -> Double? {
      guard !values.isEmpty else { return nil }
      let index = min(Int((Double(values.count - 1) * fraction).rounded(.up)), values.count - 1)
      return Double(values[index]) / 1_000_000
    }
  }

  @available(macOS 15.0, *)
  private final class AudioGainControl: @unchecked Sendable {
    private let bits = Atomic<UInt64>(1.0.bitPattern)

    var value: Double {
      Double(bitPattern: bits.load(ordering: .relaxed))
    }

    func set(_ value: Double) {
      bits.store(value.bitPattern, ordering: .relaxed)
    }
  }

  struct AudioGainMetricSnapshot: Sendable {
    let inputRMS: Double
    let postGainRMS: Double
    let callbackCount: UInt64
    let inputBufferCount: UInt64
    let outputBufferCount: UInt64
    let inputBufferBytes: UInt64
    let outputBufferBytes: UInt64
    let inputChannels: UInt64
    let outputChannels: UInt64
    let callbackLatencyP50Milliseconds: Double?
    let callbackLatencyP95Milliseconds: Double?
    let callbackLatencyMaximumMilliseconds: Double?
  }

  enum AudioGainValue {
    static func normalized(_ value: Double) -> Double {
      guard value.isFinite else { return 1 }
      return min(max(value, 0), 1)
    }
  }

  private enum AudioGainProofOfConceptError: LocalizedError {
    case coreAudio(String, status: OSStatus)
    case cleanup([String])
    case unsupportedFormat(String)

    var errorDescription: String? {
      switch self {
      case .coreAudio(let operation, let status):
        "\(operation) failed (Core Audio status \(status), 0x\(String(UInt32(bitPattern: status), radix: 16)))."
      case .cleanup(let failures):
        "Audio cleanup needs retry: \(failures.joined(separator: "; "))"
      case .unsupportedFormat(let message):
        message
      }
    }
  }
#endif
