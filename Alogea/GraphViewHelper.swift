//
//  GraphViewHelper.swift
//  Alogea
//
//  Created by mikeMBP on 29/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import Foundation
import UIKit

class GraphViewHelper: NSObject {
    
    weak var graphView: GraphView!
    let colorScheme = ColorScheme.sharedInstance()
    
    // MARK: - Horizontal line format
    let horizontalLineColor = ColorScheme.sharedInstance().lightGray
    let horizontalLineWidth: CGFloat = 1.0
    
    // MARK: - LineGraph format
    let lineGraphCircleRadius: CGFloat = 4.0
    let lineGraphCircleLineWidth: CGFloat = 3.0
    let lineGraphLineWidth: CGFloat = 2.0
    let lineCircleFillColor = ColorScheme.sharedInstance().darkBlue

    // MARK: - BarGraph format
    let barWidth: CGFloat = 8.0
    let barCornerRadius: CGFloat = 8.0 / 6
    let barRimColor = UIColor.white
    let barRimWidth: CGFloat = 1.5
    
    
    // MARK: - GraphView2 timeLine formats
    let tLLineWidth: CGFloat = 2.0
    let tLLineColor = UIColor.white

    convenience init(graphView: GraphView) {
        self.init()
        
        self.graphView = graphView
    }
    
    func lineGraphGradient() -> CGGradient {
        
        let colourSpace = CGColorSpaceCreateDeviceRGB()
        let gradientStartColour = colorScheme.lightGray.withAlphaComponent(0.8)
        let gradientEndColour = colorScheme.lightGray.withAlphaComponent(0.0)
        let graphGradientColours = [gradientStartColour.cgColor, gradientEndColour.cgColor]
        let graphColourLocations:[CGFloat] = [0.0, 1.0]
        return CGGradient(colorsSpace: colourSpace, colors: graphGradientColours as CFArray, locations: graphColourLocations)!
        
    }
    
    func barGraphGradient() -> CGGradient {
        
        let colourSpace = CGColorSpaceCreateDeviceRGB()
        let colourLocationsForColumns: [CGFloat] = [0.2,0.5,0.8,1.0]
        let coloursForColumns = [UIColor.red.cgColor, UIColor.orange.cgColor, UIColor.yellow.cgColor,UIColor.green.cgColor]
        return CGGradient(colorsSpace: colourSpace, colors: coloursForColumns as CFArray, locations: colourLocationsForColumns)!
    }

}
