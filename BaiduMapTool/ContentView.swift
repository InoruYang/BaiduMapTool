//
//  ContentView.swift
//  BaiduMapTool
//
//  Created by yaca on 2021/3/17.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var manager = MapSearch()
    
    var body: some View {
        ZStack() {
            MapView(data: manager)
            VStack() {
                Text(manager.areaText)
                    .padding(.all, 8.0)
                    .disabled(true)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.0))
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(radius: 20)
                    )
                    .opacity(0.6)
                Spacer()
            }.padding(.vertical, 8)
            if manager.isDrawArea {
                DrawView(updatePointsHandler: { (points) in
                    manager.updateSelectArea(points: points)
                })
            }

        }
        VStack() {
            HStack() {
                Spacer()
                Button(action: {
                    withAnimation{
                        manager.drawAreaAction()
                    }
                }) {
                    Text(manager.isDrawArea ? "取消绘制区域" : "开始绘制区域")
                        .padding(.all, 10.0)
                        .background(
                            RoundedRectangle(cornerRadius: 20.0)
                                .stroke(Color.gray.opacity(0.0), lineWidth: 1.0)
                                .background(Color.white)
                                .cornerRadius(20.0)
                                .shadow(radius: 20.0)
                    )
                }
            }.padding(
                EdgeInsets(
                    top: 4.0, leading: 8.0, bottom: 4.0, trailing: 8.0))
            getDivider()
            HStack(){
                Text(manager.tip)
                Spacer()
                Button(action: {
                    manager.search()
                }) {
                    Text(manager.isSearching ? "正在搜索" : "开始搜索")
                        .padding(.horizontal, 12.0)
                        .padding(.vertical, 8.0)
                        .background(
                            RoundedRectangle(cornerRadius: 20.0)
                                .stroke(Color.gray.opacity(0))
                                .background(Color.white)
                                .cornerRadius(20.0)
                                .shadow(radius: 20.0)
                        )
                }.disabled(manager.isSearching)
            }.padding(.horizontal, 8.0)
            .padding(.bottom, 16.0)
            
        }
    }
    
    func getDivider() -> some View {
        Rectangle()
            .frame(height: 0.5)
            .foregroundColor(Color(#colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
