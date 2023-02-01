//
//  CSDataSource.swift
//  DataPipeTest
//
//  Created by fuhao on 2023/1/26.
//

import Foundation
import CoreVideo


//enum CSDataFormat {
//    case Undefine
//    case PixelBuffer
//    case PCMData
//    case JsonData
//}

enum CSDataCategory : UInt32{
    case PCM = 1
    case BIN = 2
    case ARGB32 = 3
    case BGRA32 = 4
    case NV21 = 5
}

struct CSPixelParams {
    var width: Int
    var height: Int
    var dataCategory: CSDataCategory
}

struct CSPcmParams {
    var width: Int
    var height: Int
}


public class CSDataType {
    let category: CSDataCategory
    var pixelParams: CSPixelParams?
    var pcmParams: CSPcmParams?
    
    init(pixelParams: CSPixelParams) {
        self.pixelParams = pixelParams
        self.category = pixelParams.dataCategory
    }
    
    init(pcmParams: CSPcmParams) {
        self.pcmParams = pcmParams
        self.category = .PCM
    }
    
    
    func getBytesPerRow() -> Int {
        guard let pixelParams = pixelParams else {
            return 0
        }
        switch pixelParams.dataCategory {
            case .NV21  :
                return pixelParams.width + (pixelParams.width >> 1)
            default : /* 可选 */
                return pixelParams.width << 2
        }
    }
    
    func getPixelParams() -> CSPixelParams? {
        return pixelParams
    }
    
    func getRowCount() -> Int {
        guard let pixelParams = pixelParams else {
            return 0
        }
        
        return pixelParams.height
    }
    
    func getFrameSize() -> Int {
        switch category {
        case .PCM:
            return 0
        case .BIN:
            return 0
        default:
            guard let pixelParams = pixelParams else {
                return 0
            }
            return pixelParams.height * getBytesPerRow()
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
    
    
    func createCacheBuffer() {
        guard let dataType = dataType else {
            fatalError("Function onRegisterDataType return is nil")
        }
        
        if(dataType.category == .PCM) {
            cs_data_cache_create_data_cache(nativePtr, Int32(dataType.getFrameSize()) )
        }else if(dataType.category == .BIN) {
            cs_data_cache_create_data_cache(nativePtr, Int32(dataType.getFrameSize()) )
        }else{
            guard let pixelParams = dataType.pixelParams else {
                fatalError("Function onRegisterDataType return pixelParams is nil")
            }
            cs_data_cache_create_video_data_cache(nativePtr, Int32(pixelParams.width), Int32(pixelParams.height), CSDataCategoryNative(pixelParams.dataCategory.rawValue))
        }
        
        
        
    }
    
    func handleInit() {
        guard let nodeProtocol = self as? any CSNodeProtocol else {
            fatalError("Conver data type error")
        }
        
        let dataType = nodeProtocol.onRegisterDataType()
        self.dataType = dataType
        
        createCacheBuffer()
        makeRelationShip()
        nodeProtocol.onInit()
    }
    
    
    
    func storePixelData(pixelBuffer: CVPixelBuffer) {
        guard let dataType = dataType,
              dataType.category == CSDataCategory(rawValue: cs_data_cache_get_data_category(nativePtr).rawValue) else {
            fatalError("InputType is wrong")
        }
        
        
        
        //Store data to cache
        let dataCachePointer: UnsafeMutablePointer<CSDataWrapNative> = cs_data_cache_lock_data_cache(nativePtr)
        let destinationPointer: UnsafeMutableRawPointer = dataCachePointer.pointee.data
        CSDataUtils.copyPixelBuffer2Binary(pixelBuffer: pixelBuffer, binaryPointer: destinationPointer, dataSizePerRow: dataType.getBytesPerRow())
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
