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



protocol CSDataSourceProtocol {
    //push pixel to source
    func pushPixelData(pixelBuffer: CVPixelBuffer)

}





class CSUnitBase<Model> {
    var nativePtr: UnsafeMutablePointer<Model>? = nil
    var inputType: CSDataFormat = .Undefine
    
    func onInit() {}
    func onRelease() {}
    func registerInputDataFormat(index: Int, type: CSDataFormat){
        if index != 0 {
            fatalError("Current index variable only support zero!!")
        }
        
        inputType = type
    }
}


class CSDataSource : CSUnitBase<CSDataSourceNative>, CSDataSourceProtocol {
    
    
    override func onInit() {
        nativePtr = cs_data_source_create()
    }
    
    
    override func registerInputDataFormat(index: Int, type: CSDataFormat) {
        super.registerInputDataFormat(index: index, type: type)
        
        
        //TODO: - Need confirm the specific value
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
        
        cs_data_source_create_data_cache(nativePtr, Int32(cacheSize))
    }

    
    func pushPixelData(pixelBuffer: CVPixelBuffer) {
        if inputType != .PixelBuffer {
            fatalError("InputType is wrong")
        }
        
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        // Create the pointer to the destination memory
        let dataCachePointer: UnsafeMutablePointer<CSDataWrapNative> = cs_data_source_lock_data_cache(nativePtr)
        let destinationPointer: UnsafeMutableRawPointer = dataCachePointer.pointee.data
        for row in 0..<height {
            let src = baseAddress!.advanced(by: row * bytesPerRow)
            let dest = destinationPointer.advanced(by: row * width * 4)
            memcpy(dest, src, width * 4)
        }
        cs_data_source_unlock_data_cache(nativePtr, dataCachePointer)
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    }
    
}


