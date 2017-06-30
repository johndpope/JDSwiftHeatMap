//
//  JDRowDataProducer.swift
//  JDRealHeatMap
//
//  Created by 郭介騵 on 2017/6/14.
//  Copyright © 2017年 james12345. All rights reserved.
//

import Foundation
import MapKit

struct RowFormHeatData {
    var heatlevel:Float = 0
    var localCGpoint:CGPoint = CGPoint.zero
    var radius:CGFloat = 0
}

struct IntSize {
    var width:Int = 0
    var height:Int = 0
}

/**
  All this class needs to know is relative position & CGSize
  And Produce an array of rgba colro
 **/
class JDRowDataProducer:NSObject
{
    /*
        These two variable should not be modified after
    */
    var Originrowformdatas:[RowFormHeatData] = []
    var OriginCGSize:CGSize = CGSize.zero
    //
    static var theColorMixer:JDHeatColorMixer!
    var MaxHeatLevelInWholeMap:Int = 0
    //
    var RowData:[UTF8Char] = []
    var rowformdatas:[RowFormHeatData] = []
    var FitnessIntSize:IntSize!
    
    var BytesPerRow:Int
    {
        return 4 * FitnessIntSize.width
    }

    init(size:CGSize,rowHeatData:[RowFormHeatData])
    {
        super.init()
        self.Originrowformdatas = rowHeatData
        self.OriginCGSize = size
    }
    /**
        Sould not Miss this or the image size will up to GB
        (All beacuse MKMapRect Has a high definetion)
     **/
    func reduceSize(scales:Double)
    {
        let scale:CGFloat = CGFloat(scales) * 1.5
        let newWidth = Int(OriginCGSize.width * scale)
        let newHeight = Int(OriginCGSize.height * scale)
        self.FitnessIntSize = IntSize(width: newWidth, height: newHeight)
        
        func reduceRowData()
        {
            rowformdatas.removeAll()
            for origindata in Originrowformdatas
            {
                let newX = origindata.localCGpoint.x * scale
                let newY = origindata.localCGpoint.y * scale
                let newCGPoint = CGPoint(x: newX, y: newY)
                let newRadius = origindata.radius * scale
                let modifiRowFormData = RowFormHeatData(heatlevel: origindata.heatlevel, localCGpoint: newCGPoint , radius: newRadius)
                rowformdatas.append(modifiRowFormData)
            }
        }
        reduceRowData()
        RowData = Array.init(repeating: 0, count: 4 * FitnessIntSize.width * FitnessIntSize.height)
    }
    
    func produceRowData()
    {
    }
}

class JDRadiusPointRowDataProducer:JDRowDataProducer
{
    override func produceRowData()
    {
        print(#function + "w:\(FitnessIntSize.width),w:\(FitnessIntSize.height)")
        var ByteCount:Int = 0
        for h in 0..<self.FitnessIntSize.height
        {
            for w in 0..<self.FitnessIntSize.width
            {
                var destiny:Float = 0
                var involveCount:Int = 0
                for heatpoint in self.rowformdatas
                {
                    let bytesDistanceToPoint:Float = CGPoint(x: w, y: h).distanceTo(anther: heatpoint.localCGpoint)
                    let ratio:Float = 1 - (bytesDistanceToPoint / Float(heatpoint.radius))
                    if(ratio > 0)
                    {
                        involveCount += 1
                        destiny += ratio * heatpoint.heatlevel
                    }
                }
                if(MaxHeatLevelInWholeMap != 0)
                {
                    destiny /= Float(MaxHeatLevelInWholeMap)
                }
                if(destiny > 1)
                {
                    destiny = 1
                }
                //let rgb = JDRowDataProducer.theColorMixer.getRGB(inDestiny: destiny)
                let rgb = JDRowDataProducer.theColorMixer.getClearify(inDestiny: destiny)
                let redRow:UTF8Char = rgb.redRow
                let greenRow:UTF8Char = rgb.greenRow
                let BlueRow:UTF8Char = rgb.BlueRow
                let alpha:UTF8Char = UTF8Char(Int(destiny * 255))
                self.RowData[ByteCount] = redRow
                self.RowData[ByteCount+1] = greenRow
                self.RowData[ByteCount+2] = BlueRow
                self.RowData[ByteCount+3] = alpha
                ByteCount += 4
            }
        }
    }
}

class JDDotPointRowDataProducer:JDRowDataProducer
{
    override func produceRowData()
    {
        print(#function + "w:\(FitnessIntSize.width),w:\(FitnessIntSize.height)")
        var ByteCount:Int = 0
        for h in 0..<self.FitnessIntSize.height
        {
            for w in 0..<self.FitnessIntSize.width
            {
                var destiny:Float = 0
                var MaxDistance:Float = 0.0
                for heatpoint in self.rowformdatas
                {
                    let bytesDistanceToPoint:Float = CGPoint(x: w, y: h).distanceTo(anther: heatpoint.localCGpoint)
                    MaxDistance = (bytesDistanceToPoint > MaxDistance) ? bytesDistanceToPoint : MaxDistance
                }
                for heatpoint in self.rowformdatas
                {
                    let bytesDistanceToPoint:Float = CGPoint(x: w, y: h).distanceTo(anther: heatpoint.localCGpoint)
                    if(MaxHeatLevelInWholeMap != 0)
                    {
                        let ratio = (MaxDistance - bytesDistanceToPoint)/MaxDistance
                        destiny += ratio * heatpoint.heatlevel/Float(MaxHeatLevelInWholeMap)
                    }
                }
                destiny /= Float(self.rowformdatas.count)
                if(destiny > 0.5)
                {
                
                    destiny = 1
                }
                //let rgb = JDRowDataProducer.theColorMixer.getRGB(inDestiny: destiny)
                let rgb = JDRowDataProducer.theColorMixer.getClearify(inDestiny: destiny)
                let redRow:UTF8Char = rgb.redRow
                let greenRow:UTF8Char = rgb.greenRow
                let BlueRow:UTF8Char = rgb.BlueRow
                let alpha:UTF8Char = UTF8Char(Int(destiny * 255))
                self.RowData[ByteCount] = redRow
                self.RowData[ByteCount+1] = greenRow
                self.RowData[ByteCount+2] = BlueRow
                self.RowData[ByteCount+3] = alpha
                ByteCount += 4
            }
        }
    }
}



extension CGPoint
{
    func distanceTo(anther point:CGPoint)->Float
    {
        let diffx = (self.x - point.x) * (self.x - point.x)
        let diffy = (self.y - point.y) * (self.y - point.y)
        return sqrtf(Float(diffx + diffy))
    }
}
