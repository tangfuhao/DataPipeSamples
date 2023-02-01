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

enum CSColorSpace {
    case RGBA32
    case BGRA32
    case NV21
}

struct CSPixelParams {
    var width: Int
    var height: Int
    var colorSpace: CSColorSpace
}

struct CSPcmParams {
    var width: Int
    var height: Int
    var colorSpace: CSColorSpace
}


public class CSDataType {
    let format: CSDataFormat
    var pixelParams: CSPixelParams?
    var pcmParams: CSPcmParams?
    
    init(format: CSDataFormat, pixelParams: CSPixelParams) {
        self.format = format
        self.pixelParams = pixelParams
    }
    
    init(format: CSDataFormat, pcmParams: CSPcmParams) {
        self.format = format
        self.pcmParams = pcmParams
    }
    
    
    func getBytesPerRow() -> Int {
        guard let pixelParams = pixelParams else {
            return 0
        }
        switch pixelParams.colorSpace {
            case .NV21  :
                return pixelParams.width + (pixelParams.width >> 1)
            default : /* 可选 */
                return 4 * pixelParams.width
        }
    }
    
//    //TODO need fix bugs
//    func getPixelSize() -> Float{
//        guard let pixelParams = pixelParams else {
//            return 0
//        }
//
//        switch pixelParams.colorSpace {
//        case .NV21:
//            return 1.5
//        case .BGRA32: break
//        case .RGBA32:
//            return 4
//        }
//
//        return 1.5
//    }
//
    func getFrameSize() -> Int {
        switch format {
        case .PixelBuffer:
            guard let pixelParams = pixelParams else {
                return 0
            }
            return pixelParams.height * getBytesPerRow()
        case .Undefine:
            return 0
        case .PCMData:
            return 0
        case .JsonData:
            return 0
        }
    }
}



public typealias CSSourcePProtocol = CSSourceNodeImplement & CSNodeProtocol

public protocol CSNodeProtocol : AnyObject {
    func onInit()
    func onRelease()
    func onRegisterDataType() -> CSDataType
}




//Source
public class CSSourceNodeImplement {
    var dataType: CSDataType?
    var isDetermineCacheSize = false
    var nativePtr: UnsafeMutableRawPointer?
    
    init() {
        guard let nativePtr = createNativePtr() else {
            return
        }
        self.nativePtr = nativePtr
        
        //binding weak ref
        let swiftObjectRef = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
        cs_data_header_binding(nativePtr, swiftObjectRef);
        
        cs_data_source_register_onInit_function(nativePtr) { swiftObjectRef in
            guard let pointer = swiftObjectRef else {
                return
            }

            let unitWeakRef = Unmanaged<CSSourceNodeImplement>.fromOpaque(pointer).takeUnretainedValue()
            unitWeakRef.handleInit()
            
            

        }
        
    }
    
    deinit {
        guard let nativePtr = nativePtr else {
            return
        }
        
        releaseNativePtr(ptr: nativePtr)
    }
    
    
    
    
    func handleInit() {
        guard let nodeProtocol = self as? any CSNodeProtocol else {
            fatalError("Conver data type error")
        }
        
        let dataType = nodeProtocol.onRegisterDataType()
        self.dataType = dataType
        
        
        
        let dataSize = dataType.getFrameSize()
        
        cs_data_cache_create_data_cache(nativePtr, Int32(dataSize))
        makeRelationShip()
        nodeProtocol.onInit()
    }
    
    
    
    func storePixelData(pixelBuffer: CVPixelBuffer) {
        guard let dataType = dataType,
              dataType.format == .PixelBuffer else {
            fatalError("InputType is wrong")
        }
        
        
        
        //Store data to cache
        let dataCachePointer: UnsafeMutablePointer<CSDataWrapNative> = cs_data_cache_lock_data_cache(nativePtr)
        let destinationPointer: UnsafeMutableRawPointer = dataCachePointer.pointee.data
        CSDataUtils.convertPixelBuffer2Binary(pixelBuffer: pixelBuffer, binaryPointer: destinationPointer, dataSizePerRow: dataType.getBytesPerRow())
        cs_data_cache_unlock_data_cache(nativePtr)
        

        
    }
    
    //Make nodes fixed
    func makeRelationShip() {
        
        //binding strong ref
        let swiftObjectRef = UnsafeRawPointer(Unmanaged.passRetained(self).toOpaque())
        cs_data_header_binding(nativePtr, swiftObjectRef);
        

        //register functions
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
