//
//  DrawView.swift
//  BaiduMapTool
//
//  Created by yaca on 2021/6/15.
//

import SwiftUI

struct DrawView: UIViewRepresentable {
    
    var updatePointsHandler: (([CGPoint]) -> Void)?
    
    func makeUIView(context: Context) -> _DrawView {
        let view = _DrawView()
        view.updatePointsHandler = updatePointsHandler
        return view
    }
    
    func updateUIView(_ uiView: _DrawView, context: Context) {
        
    }
}


class _DrawView: UIView {
    
    private(set) var path: UIBezierPath = UIBezierPath()
    private(set) var points: [CGPoint] = []
    var updatePointsHandler: (([CGPoint]) -> Void)?
    
    let boardLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = 1
        layer.fillColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
        layer.strokeColor = #colorLiteral(red: 0.1960784314, green: 0.8431372549, blue: 0.2941176471, alpha: 1)
        layer.lineCap = .round
        return layer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        boardLayer.frame = bounds
    }
    
    func setupViews() {
        
        // add
        layer.addSublayer(boardLayer)
        
        // layout

        
        // config
    }
    
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let point = touch.location(in: self)
        path.removeAllPoints()
        points.removeAll()
        path.move(to: point)
        boardLayer.path = path.cgPath
        points.append(point)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch = touches.first else {
            return
        }
        let point = touch.location(in: self)
        path.addLine(to: point)
        boardLayer.path = path.cgPath
        points.append(point)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch = touches.first else {
            return
        }
        let point = touch.location(in: self)
        path.addLine(to: point)
        path.close()
        boardLayer.path = path.cgPath
        points.append(point)
        if let first = points.first {
            points.append(first)
        }
        updatePointsHandler?(points)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
}

struct DrawView_Previews: PreviewProvider {
    static var previews: some View {
        DrawView()
    }
}
