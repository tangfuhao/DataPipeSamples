//
//  CSDataSource.swift
//  DataPipeTest
//
//  Created by fuhao on 2023/1/26.
//

import Foundation
import CoreVideo


enum CSDataFormat {
    case Undefine
    case PixelBuffer
    case PCMData
    case JsonData
}


protocol CSUnitBaseProtocol {
    func onInit()
    func onRelease()
    func pushPixelData(pixelBuffer: CVPixelBuffer)
}









struct CSDataType {
    var format: CSDataFormat
}

protocol CSNodeProtocol : AnyObject {
    func onInit()
    func onRelease()
    func onRegisterDataType() -> CSDataType

}

protocol CSNodeProcessorProtocol : CSNodeProtocol {
    func onProcess()
}



//Source
class CSSourceNodeImplement {
//    weak var delegate: CSNodeProtocol?
    var nativePtr: UnsafeMutableRawPointer?
    
    init() {
        print("CSUnitBase init")
//        let mySelf = getMMMMMM()
//        self.delegate = mySelf as? any CSNodeProtocol
//        self.nativeDelegate = mySelf as? any CSNativeProtocol
        
        guard let nativePtr = createNativePtr() else {
            return
        }
        self.nativePtr = nativePtr
    }
    
    deinit {
        print("CSUnitBase deinit")
        guard let nativePtr = nativePtr else {
            return
        }
        
        releaseNativePtr(ptr: nativePtr)
    }
    
    
    
    func storePixelData(pixelBuffer: CVPixelBuffer) {
        //Store data to cache
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        // Create the pointer to the destination memory
        let dataCachePointer: UnsafeMutablePointer<CSDataWrapNative> = cs_data_cache_lock_data_cache(nativePtr)
        let destinationPointer: UnsafeMutableRawPointer = dataCachePointer.pointee.data
        for row in 0..<height {
            let src = baseAddress!.advanced(by: row * bytesPerRow)
            let dest = destinationPointer.advanced(by: row * width * 4)
            memcpy(dest, src, width * 4)
        }
        cs_data_cache_unlock_data_cache(nativePtr)
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    }
    
    //Make nodes fixed
    func makeRelationShip() {
        
        //register functions
        let swiftObjectRef = UnsafeRawPointer(Unmanaged.passRetained(self).toOpaque())
        cs_data_header_binding(nativePtr, swiftObjectRef);
        
        cs_data_source_register_onInit_function(nativePtr) { swiftObjectRef in
            guard let pointer = swiftObjectRef else {
                return
            }

            let unitWeakRef = Unmanaged<CSSourceNodeImplement>.fromOpaque(pointer).takeUnretainedValue()
            guard let delegate = unitWeakRef as? any CSNodeProtocol else {
                return
            }
            delegate.onInit()
        }
        
        cs_data_source_register_onRelease_function(nativePtr) { swiftObjectRef in
            guard let pointer = swiftObjectRef else {
                return
            }

            let unitWeakRef = Unmanaged<CSSourceNodeImplement>.fromOpaque(pointer).takeRetainedValue()
            guard let delegate = unitWeakRef as? any CSNodeProtocol else {
                return
            }
            delegate.onRelease()
        }
    }
    
    func releaseNativePtr(ptr: UnsafeMutableRawPointer) {
        cs_data_source_release(ptr)
    }
    
    func createNativePtr() -> UnsafeMutableRawPointer? {
        return cs_data_source_create()
    }
    
}


class CSProcessorNodeImplement : CSSourceNodeImplement {
    override func releaseNativePtr(ptr: UnsafeMutableRawPointer) {
        cs_data_processor_release(ptr)
    }
    
    override func createNativePtr() -> UnsafeMutableRawPointer? {
        return cs_data_processor_create()
    }
    
    override func makeRelationShip() {
        super.makeRelationShip()
        cs_data_processor_register_onProcess_function(nativePtr) { swiftObjectRef in
            guard let pointer = swiftObjectRef else {
                return
            }

            let unitWeakRef = Unmanaged<CSSourceNodeImplement>.fromOpaque(pointer).takeUnretainedValue()
            guard let delegate = unitWeakRef as? any CSNodeProcessorProtocol else {
                return
            }
            delegate.onProcess()
        }

    }
}



typealias CSSourcePProtocol = CSSourceNodeImplement & CSNodeProtocol



class cameraSourceff : CSSourcePProtocol {
    func onInit() {
        
    }
    
    func onRelease() {
        
    }
    
    func onRegisterDataType() -> CSDataType {
        return CSDataType(format: .PixelBuffer)
    }
    
}





class CSUnitBase : CSUnitBaseProtocol{
    var nativePtr: UnsafeMutableRawPointer?
    var inputType: CSDataFormat = .Undefine
    var isDetermineCacheSize = false
    
    init() {
        print("CSUnitBase init")
        
        
        
        guard let nativePtr = cs_data_source_create() else {
            return
        }
        
        self.nativePtr = nativePtr
    }
    
    deinit {
        
        print("CSUnitBase deinit")
    }
    
    
    func onInit() {
        let swiftObjectRef = UnsafeRawPointer(Unmanaged.passRetained(self).toOpaque())
        cs_data_header_binding(nativePtr, swiftObjectRef);
        
        cs_data_source_register_onInit_function(nativePtr) { swiftObjectRef in
            guard let pointer = swiftObjectRef else {
                return
            }

            let unitWeakRef = Unmanaged<CSUnitBase>.fromOpaque(pointer).takeUnretainedValue()
            unitWeakRef.onInit()
        }
        cs_data_source_register_onRelease_function(nativePtr) { swiftObjectRef in
            guard let pointer = swiftObjectRef else {
                return
            }

            let unitWeakRef = Unmanaged<CSUnitBase>.fromOpaque(pointer).takeRetainedValue()
            unitWeakRef.onRelease()
        }
        
    }
    func onRelease() {
        
    }
    
    
    func registerInputDataFormat(index: Int, type: CSDataFormat){
        if index != 0 {
            fatalError("Current index variable only support zero!!")
        }
        
        inputType = type
    }
    
    func pushPixelData(pixelBuffer: CVPixelBuffer) {
        if (!isDetermineCacheSize) {
            var cacheSize = 0
            switch inputType {
            case .PixelBuffer:
                cacheSize = 360*240*4
                break
            case .PCMData:
                break
            case .JsonData:
                break
            case .Undefine:
                break
            }
            
            cs_data_cache_create_data_cache(nativePtr, Int32(cacheSize))
            isDetermineCacheSize = true
        }
    }
    
}


class CSDataSource : CSUnitBase {

    override func pushPixelData(pixelBuffer: CVPixelBuffer) {
        super.pushPixelData(pixelBuffer: pixelBuffer)
        
        if inputType != .PixelBuffer {
            fatalError("InputType is wrong")
        }
        
        
        //Store data to cache
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        // Create the pointer to the destination memory
        let dataCachePointer: UnsafeMutablePointer<CSDataWrapNative> = cs_data_cache_lock_data_cache(nativePtr)
        let destinationPointer: UnsafeMutableRawPointer = dataCachePointer.pointee.data
        for row in 0..<height {
            let src = baseAddress!.advanced(by: row * bytesPerRow)
            let dest = destinationPointer.advanced(by: row * width * 4)
            memcpy(dest, src, width * 4)
        }
        cs_data_cache_unlock_data_cache(nativePtr)
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    }
    
}


