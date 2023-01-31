//
//  CSDataProcessor.swift
//  DataPipeTest
//
//  Created by fuhao on 2023/1/26.
//

import Foundation
import CoreVideo

public protocol CSNodeProcessorProtocol : CSNodeProtocol {
    func onProcess()
}

public typealias CSProcessorPProtocol = CSProcessorNodeImplement & CSNodeProcessorProtocol


public class CSProcessorNodeImplement : CSSourceNodeImplement {
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
    
    
    func getInputPixel(index: Int) -> CVPixelBuffer? {
        let width = 640
        let height = 480
        let bytesPerRow = width * 4

        guard let dataCachePointer = cs_data_processor_get_input_data(nativePtr, Int32(index)) else {
            return nil
        }

        let pixelData = dataCachePointer.pointee.data!
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreateWithBytes(nil, width, height, kCVPixelFormatType_32BGRA, pixelData, bytesPerRow, nil, nil, nil, &pixelBuffer)

        return pixelBuffer
    }
    
    func connectInput(input: CSSourceNodeImplement) {
        cs_data_processor_connect_dep(nativePtr,input.nativePtr)
    }
}
