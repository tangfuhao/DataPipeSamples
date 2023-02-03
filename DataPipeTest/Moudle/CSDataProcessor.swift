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
        
        guard let inputNode = cs_data_processor_get_input_node(nativePtr, Int32(index)),
              let dataCachePointer = cs_data_cache_read_data_cache(inputNode) else {
            return nil
        }
        
        let category = cs_data_cache_get_data_category(inputNode)
        let width = Int(cs_data_cache_get_width(inputNode))
        let bytesPerRow = Int(cs_data_cache_get_bytes_per_row(inputNode))
        
        let dataSize = Int(dataCachePointer.pointee.dataSize)
        let pixelData = dataCachePointer.pointee.data!
        let height = dataSize/bytesPerRow
        
        var pixelBuffer: CVPixelBuffer?
        
        
        
        if CSDataCategory(rawValue: category.rawValue) == .NV21  {
//            let ysize = width * height        // Y is full width & height in YUV 4:2:0
//           let usize = ysize >> 2   // U is half width & height
            let widthY = width
            let widthUV = width
            let heightY = height
            let heightUV = heightY >> 1
            
            
            let planeY = pixelData
            let planeUV = pixelData.advanced(by: widthY * heightY)
            

            
            
            let planeBaseAddress = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: 2)
            planeBaseAddress.advanced(by: 0).pointee = planeY
            planeBaseAddress.advanced(by: 1).pointee = planeUV

            
            let planeWidth = UnsafeMutablePointer<Int>.allocate(capacity: 2)
            planeWidth.advanced(by: 0).pointee = widthY
            planeWidth.advanced(by: 1).pointee = widthUV


            let planeHeight = UnsafeMutablePointer<Int>.allocate(capacity: 2)
            planeHeight.advanced(by: 0).pointee = heightY
            planeHeight.advanced(by: 1).pointee = heightUV
            
            let planeBytesPerRow = UnsafeMutablePointer<Int>.allocate(capacity: 2)
            planeBytesPerRow.advanced(by: 0).pointee = widthY
            planeBytesPerRow.advanced(by: 1).pointee = widthUV
     
            let options = [ kCVPixelBufferMetalCompatibilityKey as String: true ] as [String: Any]
            CVPixelBufferCreateWithPlanarBytes(kCFAllocatorDefault, Int(width), Int(height), kCVPixelFormatType_420YpCbCr8Planar, pixelData, Int(dataSize), 2, planeBaseAddress, planeWidth, planeHeight, planeBytesPerRow, nil, nil, options as CFDictionary, &pixelBuffer)
            
            

        }else{
            CVPixelBufferCreateWithBytes(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, pixelData, Int(bytesPerRow), nil, nil, nil, &pixelBuffer)
        }
        
        

        return pixelBuffer
    }
    
    
    //TODO: index is useless
    func addInputNode(index: Int, input: CSSourceNodeImplement) {
        cs_data_processor_connect_dep(nativePtr,input.nativePtr)
    }
}
