//
//  ViewController.swift
//  DataPipeTest
//
//  Created by fuhao on 2023/1/19.
//

import UIKit

class ViewController: UIViewController {
    var dataPipe: CSDataPipe?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        //create data pipe
        let dataPipe = CSDataPipe()
        self.dataPipe = dataPipe
        
        let dataSource = CameraSource()
        let dataProcesser = YUV2RGBProcessor()
        dataProcesser.connectInput(input: dataSource)
        dataPipe.setMainInputAndOutput(input: dataSource, output: dataProcesser)
        
        dataPipe.receiverCVPixelBuffer { pixelBuffer in
            print("width: \(CVPixelBufferGetWidth(pixelBuffer))")
        }
        
        


//        var dataProcesser2 = CSDataProcessor()
//
//        dataProcesser.addInput(source: dataSource,index: 0)
//        dataProcesser2.addInput(source: dataSource, index: 0)
        
    }


}

