//
//  CustomProcessor.swift
//  DataPipeTest
//
//  Created by fuhao on 2023/1/29.
//

import Foundation

class CustomProcessor : CSProcessorPProtocol {
    func onProcess() {
        
    }
    
    func onInit() {
        
    }
    
    func onRelease() {
        
    }
    
    func onRegisterDataType() -> CSDataType {
        return CSDataType(format: .PixelBuffer, pixelParams: CSPixelParams(width: 640, height: 480, colorSpace: .BGRA32))
    }
    
    
}
