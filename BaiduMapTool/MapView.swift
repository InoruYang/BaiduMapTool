//
//  MapView.swift
//  BaiduMapTool
//
//  Created by yaca on 2021/3/17.
//

import SwiftUI

struct MapView: UIViewRepresentable {
    
    typealias UIViewType = BMKMapView
    @ObservedObject var data: MapSearch
    
    func makeUIView(context: Context) -> BMKMapView {
        let map = BMKMapView(frame: .zero)
        data.config(mapView: map)
        return map
    }
    
    func updateUIView(_ uiView: BMKMapView, context: Context) {
        
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(data: MapSearch())
    }
}
