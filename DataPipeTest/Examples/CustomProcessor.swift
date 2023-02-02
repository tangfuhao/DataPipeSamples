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
    
    func onRegisterInputDataType() -> [CSDataType] {
        return [CSDataType(pixelParams: CSPixelParams(width: 640, height: 480, dataCategory: .BGRA32))]
    }
    
    func onRegisterOutputDataType() -> CSDataType {
        return CSDataType(pixelParams: CSPixelParams(width: 640, height: 480, dataCategory: .BGRA32))
    }
    
    
}
