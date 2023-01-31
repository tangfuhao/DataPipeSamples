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
        
        
        //Create data pipe
        let dataPipe = CSDataPipe()
        self.dataPipe = dataPipe

        let dataSource = CameraSource()
        let dataProcesser = YUV2RGBProcessor()
        dataProcesser.connectInput(input: dataSource)
        dataPipe.setMainInputAndOutput(input: dataSource, output: dataProcesser)

        dataPipe.ReceiveData { pixelBuffer in
            print("width: \(CVPixelBufferGetWidth(pixelBuffer))")
        }
//        dataPipe.PullPixelData()
        
        
        
        
    }


}

