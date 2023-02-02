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
    func onRegisterInputDataType() -> [CSDataType]
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
        
//        cs_data_processor_get_input_node(nativePtr, index)

        
        guard let inputNode = cs_data_processor_get_input_node(nativePtr, Int32(index)),
              let dataCachePointer = cs_data_cache_read_data_cache(inputNode) else {
            return nil
        }
        
        let category = cs_data_cache_get_data_category(inputNode)
        let width = cs_data_cache_get_width(inputNode)
        let bytesPerRow = cs_data_cache_get_bytes_per_row(inputNode)
        
        let dataSize = dataCachePointer.pointee.dataSize
        let pixelData = dataCachePointer.pointee.data!
        let height = dataSize/bytesPerRow
        
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreateWithBytes(kCFAllocatorDefault, Int(width), Int(height), kCVPixelFormatType_32BGRA, pixelData, Int(bytesPerRow), nil, nil, nil, &pixelBuffer)

        return pixelBuffer
    }
    
    
    //TODO: index is useless
    func addInputNode(index: Int, input: CSSourceNodeImplement) {
        cs_data_processor_connect_dep(nativePtr,input.nativePtr)
    }
}
