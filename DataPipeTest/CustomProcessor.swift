//
//  CustomProcessor.swift
//  DataPipeTest
//
//  Created by fuhao on 2023/1/29.
//

import Foundation



class CustomProcessor : CSDataProcessor {
    override func onInit() {
        super.onInit()
        //Register #1 input data
        registerInputDataFormat(index: 0, type: .PixelBuffer)
    }
}
