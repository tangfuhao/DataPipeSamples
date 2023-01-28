//
//  CSDataSource.swift
//  DataPipeTest
//
//  Created by fuhao on 2023/1/26.
//

import Foundation
import CoreVideo


//struct User {
//
//}
//
//protocol LoadableProtocol {
//    associatedtype Model
//    func load(from url: URL) async throws -> Model
//}
//
//extension LoadableProtocol {
//    func loadWithCaching(from url: URL) async throws -> Model {
////        if let cachedModel = cache.value(forKey: url) {
////            return cachedModel
////        }
//        let model = try await load(from: url)
////        cache.insert(model, forKey: url)
//        return model
//    }
//}
//
//class UserLoader: LoadableProtocol {
//    typealias Model = User
//
//    func load(from url: URL) async throws -> User {
//        return User()
//    }
//}

protocol LoadableProtocol {
    func setPixelData(pixelBuffer: CVPixelBuffer)
    
    //set up input data params
    func setInputDataParams(params: [String:String]?)
}


protocol CSUnitProtocol : Any{
    associatedtype Model
    func onInit()
    func onRelease()
    func getNativePtr() -> UnsafeMutablePointer<Model>
}

class CSDataSourceBase : CSUnitProtocol {
    typealias Model = CSDataSourceNative
    let nativePtr = cs_data_source_create()
    
    func getNativePtr() -> UnsafeMutablePointer<CSDataSourceNative> {
        return nativePtr!
    }

    func onInit() {
        
    }
    
    func onRelease() {
        
    }
    
    
}


typealias CSDataSourceProtocol = LoadableProtocol & CSDataSourceBase


class CSDataSource : CSDataSourceProtocol {
    func setInputDataParams(params: [String : String]?) {
        
    }
    

    
    func setPixelData(pixelBuffer: CVPixelBuffer) {
        // Copy the data from the pixel buffer to the destination pointer
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

        let dataCachePointer: UnsafeMutablePointer<CSDataWrapNative> = cs_data_source_lock_data_cache(nativePtr)


        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        // Create the pointer to the destination memory
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


