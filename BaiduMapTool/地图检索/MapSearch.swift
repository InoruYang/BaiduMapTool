//
//  MapSearch.swift
//  BaiduMapTool
//
//  Created by yaca on 2021/3/17.
//

import SwiftUI

class MapSearch: ObservableObject {
    
    @Published var tip: String = "ready"
    @Published var areaText: String = "(0, 0, \n0, 0)"
    @Published var isDrawArea: Bool = false
    @Published var isSearching: Bool = false
    
    private lazy var searchEngine = MapSearchEngine()
    private var sourceList: [ItemData] = []
    private var runIndex: Int = -1
    private var fileHandle: FileHandle!
    
//    private var selectArea: UIBezierPath?
    private var selectAreaPoints: [CGPoint] = []
    private var selectAreaPolygon: BMKPolygon? = nil
    
    let delegateManager: MapViewDelegateManager = MapViewDelegateManager()
    
    
    private var newCityMap: [String: String] = [:]
    
    func search() {
        isSearching = true
        readNewCityMapData()
        readJsonData()
        start()
    }
    
    func drawAreaAction() {
        isDrawArea.toggle()
    }
    
    func updateSelectArea(points: [CGPoint]) {
        selectAreaPoints = points
        computeVaildPaths()
    }
    
    func computeVaildPaths() {
        if selectAreaPoints.isEmpty {
            selectAreaPolygon = nil
            isDrawArea.toggle()
            return
        }
        selectAreaPolygon = delegateManager.polygon(points: selectAreaPoints)
        isDrawArea.toggle()
    }
    
    func readJsonData() {
        
        guard let fileURL = Bundle.main.url(
                forResource: "DistrictResult", withExtension: "json") else {
            tip = "无效文件地址"
            return
        }
        
        let sourceList: [ItemData]
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            sourceList = try decoder.decode([ItemData].self, from: data)
        } catch let error {
            print(error)
            tip = "\(error)"
            return
        }
        runIndex = -1
        if !self.sourceList.isEmpty {
            self.sourceList.removeAll()
        }
        self.sourceList = sourceList
    }
    
    func readNewCityMapData() {
        
        guard let url = Bundle.main.url(forResource: "NewCityMap", withExtension: "plist"),
              let data = try? Data(contentsOf: url) else {
            newCityMap = [:]
            return
        }
        
        let decoder = PropertyListDecoder()
        var format = PropertyListSerialization.PropertyListFormat.xml
        let dict = try? decoder.decode(
            [String: String].self, from: data, format: &format)
        newCityMap = dict ?? [:]
    }
    
    func start() {
        if sourceList.isEmpty {
            tip = "无有效搜索单元"
            isSearching = false
            return
        }
        do {
            let fileManager = FileManager.default
            
            let documentURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy_MM_dd_HH_mm_ss"
            let fileName = formatter.string(from: Date())
            let url = documentURL.appendingPathComponent("\(fileName).sql")
            fileManager.createFile(
                atPath: url.path, contents: nil, attributes: nil)
            fileHandle = try FileHandle(forWritingTo: url)
        } catch let error {
            print(error)
            tip = "\(error)"
            isSearching = false
            return
        }
        
        delegateManager.clearDisplayRegion()
        delegateManager.clearOverlays()
        next()
    }
    
    func next() {
        let toIndex = runIndex + 1
        if toIndex == 0 {
            tip = "-/optsCount"
        }
        guard sourceList.count > toIndex else {
            do {
                try fileHandle.close()
            } catch let error {
                print(error)
                tip = "\(error)"
            }
            
            if let polygon = selectAreaPolygon {
                delegateManager.add(polygon: polygon)
            }
            isSearching = false
            return
        }
        
        let totalCount = sourceList.count
        let item = sourceList[toIndex]
        let opt = BMKDistrictSearchOption()
        
        opt.city = item.provinceName
        opt.district = {
            if let newName = newCityMap[item.cityName] {
                return newName
            }
            return item.cityName
            
        }()
        
        searchEngine.search(option: opt) { [weak self] (name, paths) in
            guard let self = self else { return }
            
            print(#function, "name: \(name), paths count: \(paths.count)")
            
            let vailPaths = self.addPolygons(from: paths)
            self.writePaths(vailPaths, item: item, index: toIndex)
            let pageIndex = toIndex + 1
            self.runIndex = toIndex
            self.tip = "\(pageIndex)/\(totalCount)"
            DispatchQueue.main.async {
                self.next()
            }
        }
    }
    
    func writePaths(_ paths: [String], item: ItemData, index: Int) {
        if paths.isEmpty || paths.count > 1 {
            print(#function, "province: \(item.provinceName) city: \(item.cityName) path count: \(paths.count)")
        }
        
        let path = paths.reduce("", { $0 + ($0.isEmpty ? "" : "|") + $1 })
        var sql = ""
        if index != 0 {
            sql.append("\n")
        }
        sql.append("""
        UPDATE DistrictResult \
        SET \"path\"=\"\(path)\" \
        WHERE ProvinceName=\"\(item.provinceName)\" \
        AND CityName=\"\(item.cityName)\";
        """)
        
        if let data = sql.data(using: .utf8) {
            fileHandle.write(data)
        } else {
            print("【\(index + 1)】生成utf8编码失败")
        }
    }
    
    func addPolygons(from paths: [String]) -> [String] {
        var vailPaths: [String] = []
        for path in paths {
            let isVail = addPolygon(from: path)
            if isVail {
                vailPaths.append(path)
            }
        }
        return vailPaths
    }
    
    func addPolygon(from path: String) -> Bool {
        
//        let coordTexts = path.components(separatedBy: ";")
        
//        let coords = coordTexts.map({ (text) -> CLLocationCoordinate2D in
//            let texts = text.components(separatedBy: ",")
//            let longitude: CLLocationDegrees
//            if texts.count > 0,
//               let value = CLLocationDegrees(texts[0]) {
//                longitude = value
//            } else {
//                longitude = 0.0
//                print(#function, "经纬度异常: \(text)")
//            }
//            let latitude: CLLocationDegrees
//            if texts.count > 1,
//               let value = CLLocationDegrees(texts[1]) {
//                latitude = value
//            } else {
//                latitude = 0.0
//                print(#function, "经纬度异常: \(text)")
//            }
//            return CLLocationCoordinate2D(
//                latitude: latitude, longitude: longitude)
//        })
//
//        delegateManager.addPolygon(coors: coords)
        
        let pointTexts = path.components(separatedBy: ";")
        let points = pointTexts.map({ (text) -> BMKMapPoint in
            let texts = text.components(separatedBy: ",")
            let x: Double
            if texts.count > 0,
               let value = Double(texts[0]) {
                x = value
            } else {
                x = 0.0
                print(#function, "经纬度异常: \(text)")
            }
            let y: Double
            if texts.count > 1,
               let value = Double(texts[1]) {
                y = value
            } else {
                y = 0.0
                print(#function, "经纬度异常: \(text)")
            }
            return BMKMapPoint(x: x, y: y)
        })
        guard let polygon = delegateManager.transform(points: points) else {
            return false
        }
        if let ref = selectAreaPolygon {
            let rs = delegateManager.filter(
                polygons: [polygon], refPolygon: ref)
            if rs.isEmpty {
//                print(#function, "已过滤")
                return false
            }
//            print(#function, "未过滤")
        }
        delegateManager.add(polygon: polygon)
        
        return true
    }
    
    struct ItemData: Codable {
        
        let provinceName: String
        let cityName: String
        
        enum CodingKeys: String, CodingKey {
            case provinceName = "ProvinceName"
            case cityName = "CityName"
        }
    }
    
    
    func config(mapView: BMKMapView) {
        
        delegateManager.mapView = mapView
        delegateManager.willChangeRegionHandler = { [weak self] (region) in
            guard let self = self else { return }
            self.areaText = "(\(region.center.latitude), \(region.center.longitude), \n\(region.span.latitudeDelta), \(region.span.longitudeDelta))"
        }
        mapView.delegate = delegateManager
    }
}

class MapViewDelegateManager: NSObject {
    
    weak var mapView: BMKMapView?
    
    var didChangeRegionHandler: ((BMKCoordinateRegion) -> Void)?
    var willChangeRegionHandler: ((BMKCoordinateRegion) -> Void)?
    
    private var displayRegion: BMKCoordinateRegion = BMKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: BMKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0))
    
    
    func addPolygon(coors:  [CLLocationCoordinate2D]) -> BMKPolygon? {
        guard let view = mapView else {
            return nil
        }
        var _coors = coors
        let polygon = BMKPolygon(
            coordinates: &_coors, count: UInt(_coors.count))
        view.add(polygon)
        
        return polygon
    }
    
    func transform(points: [BMKMapPoint]) -> BMKPolygon? {
        var _points = points
        let polygon = BMKPolygon(points: &_points, count: UInt(_points.count))
        return polygon
    }
    
    func add(polygon:  BMKPolygon) {
        guard let view = mapView else {
            return
        }
        view.add(polygon)
    }
    
    func filter(polygons: [BMKPolygon], refPolygon: BMKPolygon) -> [BMKPolygon]  {
        let nPolugons = polygons.filter({
            return contain(source: $0, refe: refPolygon)
        })
        return nPolugons
    }
    
    func contain(source: BMKPolygon, refe: BMKPolygon) -> Bool {
        
        let sRect = source.boundingMapRect
        let rRect = refe.boundingMapRect
        
        if sRect.minX > rRect.maxX { return false }
        if sRect.maxX < rRect.minX { return false }
        if sRect.minY > rRect.maxY { return false }
        if sRect.maxY < rRect.minY { return false }
        
        guard let _sPoints = source.points else {
            return false
        }
        let count = Int(source.pointCount)
        for idx in 0..<count {
            let point = _sPoints[idx]
            let isContains = BMKPolygonContainsPoint(
                point, refe.points, refe.pointCount)
            if isContains {
//                print(#function, "sRect", sRect.des, "rRect", rRect.des)
                return true
            }
        }
        return false
    }
    
    
    
    func polygon(points: [CGPoint]) -> BMKPolygon? {
        guard let view = mapView else {
            return nil
        }
        
        var coords: [CLLocationCoordinate2D] = []
        for point in points {
            let coord = view.convert(point, toCoordinateFrom: view)
            coords.append(coord)
        }
        let polygon = BMKPolygon(coordinates: &coords, count: UInt(coords.count))
        return polygon
    }
    
    func updateDisplayArea(rect: BMKMapRect) {
        
        print(#function, rect)
        updateDisplayArea()
    }
    
    func updateDisplayArea(polygon: BMKPolygon) {
        

        
        
        
        let coor = BMKCoordinateRegionForMapRect(polygon.boundingMapRect)
        if displayRegion.isZero {
            displayRegion = coor
//            print(#function, "初始化")
        } else {
            displayRegion = displayRegion.merged(region: coor)
//            print(#function, "合并")
        }
        
        updateDisplayArea()
    }
    
    func updateDisplayArea() {
        guard let view = mapView else {
            return
        }
        view.setRegion(displayRegion, animated: true)
    }
    func clearDisplayRegion() {
        
        displayRegion = BMKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: BMKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0))
    }
    
    func clearOverlays() {
        guard let view = mapView else {
            return
        }
        guard let overlays = view.overlays as? [BMKOverlay] else {
            return
        }
        view.removeOverlays(overlays)
    }
}

extension BMKCoordinateRegion {
    
    var isZero: Bool {
        guard center.latitude == 0 else {
            return false
        }
        guard center.longitude == 0 else {
            return false
        }
        guard span.latitudeDelta == 0 else {
            return false
        }
        guard span.longitudeDelta == 0 else {
            return false
        }
        return true
    }
    
    var minLatitude: Double {
        return center.latitude - span.latitudeDelta/2.0
    }
    
    var maxLatitude: Double {
        return center.latitude + span.latitudeDelta/2.0
    }
    
    var minLongitude: Double {
        return center.longitude - span.longitudeDelta/2.0
    }
    
    var maxLongitude: Double {
        return center.longitude + span.longitudeDelta/2.0
    }
    
    func merged(region: BMKCoordinateRegion) -> BMKCoordinateRegion {
        
//        print(#function, "\n1. \(self)\n2. \(region)")
        
        let minLat = min(minLatitude, region.minLatitude)
        let minLong = min(minLongitude, region.minLongitude)
        let maxLat = max(maxLatitude, region.maxLatitude)
        let maxLong = max(maxLongitude, region.maxLongitude)
        
        let latitudeDelta = maxLat - minLat
        let longitudeDelta = maxLong - minLong
        let latitude = minLat + latitudeDelta/2.0
        let longitude = minLong + longitudeDelta/2.0
        
        return BMKCoordinateRegionMake(
            CLLocationCoordinate2DMake(latitude, longitude),
            BMKCoordinateSpan(
                latitudeDelta: latitudeDelta,
                longitudeDelta: longitudeDelta))
    }
    
}

extension BMKMapRect {
    
    var minX: Double {
        return origin.x
    }
    var maxX: Double {
        return origin.x + size.width
    }
    var minY: Double {
        return origin.y
    }
    var maxY: Double {
        return origin.y + size.height
    }
    
    var des: String {
        return "{\(origin.x), \(origin.y), \(size.width), \(size.height)}"
    }
}

extension MapViewDelegateManager: BMKMapViewDelegate {
    
    func mapView(_ mapView: BMKMapView!, viewFor overlay: BMKOverlay!) -> BMKOverlayView! {
        
        if let polygon = overlay as? BMKPolygon {
            guard let view = BMKPolygonView(polygon: polygon) else {
                print(#function, "创建区域视图异常: \(polygon)")
                return nil
            }
            view.strokeColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            let r: CGFloat = CGFloat.random(in: 0...1)
            let g: CGFloat = CGFloat.random(in: 0...1)
            let b: CGFloat = CGFloat.random(in: 0...1)
            view.fillColor = UIColor(
                displayP3Red: r, green: g, blue: b, alpha: 0.2)
            view.lineWidth = 2.0
            view.lineDashType = kBMKLineDashTypeSquare
            
            updateDisplayArea(polygon: polygon)
            
            return view
            
        }
        return nil
    }
    
    func mapView(_ mapView: BMKMapView!, regionDidChangeAnimated animated: Bool, reason: BMKRegionChangeReason) {
        didChangeRegionHandler?(mapView.region)
    }
    
    func mapView(_ mapView: BMKMapView!, regionWillChangeAnimated animated: Bool) {
        willChangeRegionHandler?(mapView.region)
    }
}

class MapSearchEngine: NSObject {
    
    private let search = BMKDistrictSearch()
    private var handler: ((String, [String]) -> Void)?
        
    override init() {
        super.init()
        search.delegate = self
    }
    
    func search(option: BMKDistrictSearchOption, finshed: @escaping (String, [String]) -> Void) {
        let st = search.districtSearch(option)
        if !st {
            print("行政区域检索发送", st ? "成功" : "失败")
        }
        handler = finshed
    }
}

extension MapSearchEngine: BMKDistrictSearchDelegate {
    
    func onGetDistrictResult(_ searcher: BMKDistrictSearch!, result: BMKDistrictResult!, errorCode error: BMKSearchErrorCode) {
        if error != BMK_SEARCH_NO_ERROR {
            print(#function, "\(error)")
        }
        
        guard let handler = self.handler else {
            return
        }
        guard let rs = result else {
            handler("", [])
            return
        }
        handler(rs.name ?? "", rs.paths ?? [])
    }
}


